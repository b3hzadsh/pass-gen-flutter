import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pass_generator/models/vault_item.dart' show VaultItem;
import 'package:pass_generator/pages/login_page.dart' show LoginPage;
import 'package:pass_generator/repository/vault_repository.dart'
    show VaultRepository;
import 'package:pass_generator/services/hash_gen.dart';
import 'package:pass_generator/services/storage_service.dart'
    show StorageService;
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

class PasswordProfile {
  final String id;
  final String label;
  final IconData icon;
  final int length;
  final bool useUpper;
  final bool useLower;
  final bool useNumbers;
  final bool useSpecial;

  PasswordProfile({
    required this.id,
    required this.label,
    required this.icon,
    required this.length,
    required this.useUpper,
    required this.useLower,
    required this.useNumbers,
    required this.useSpecial,
  });
}

class PasswordGeneratorPage extends StatefulWidget {
  final String masterSecret;
  const PasswordGeneratorPage({super.key, required this.masterSecret});

  @override
  State<PasswordGeneratorPage> createState() => _PasswordGeneratorPageState();
}

class _PasswordGeneratorPageState extends State<PasswordGeneratorPage> {
  final _serviceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();

  bool _isSaveEnabled = false;
  String _generatedCode = "";
  // متغیرهای Vault
  final VaultRepository _vaultRepo = VaultRepository();
  List<VaultItem> _vaultItems = [];
  String? _editingId;
  final List<PasswordProfile> _profiles = [
    PasswordProfile(
      id: 'bank_card',
      label: 'رمز کارت بانکی (۴ رقم)',
      icon: Icons.credit_card,
      length: 4,
      useUpper: false,
      useLower: false,
      useNumbers: true,
      useSpecial: false,
    ),
    PasswordProfile(
      id: 'pin_code',
      label: 'پین کد گوشی/برنامه (۶ رقم)',
      icon: Icons.dialpad,
      length: 6,
      useUpper: false,
      useLower: false,
      useNumbers: true,
      useSpecial: false,
    ),
    PasswordProfile(
      id: 'social',
      label: 'شبکه‌های اجتماعی (استاندارد)',
      icon: Icons.public,
      length: 12,
      useUpper: true,
      useLower: true,
      useNumbers: true,
      useSpecial: false,
    ),
    PasswordProfile(
      id: 'secure',
      label: 'کیف پول / صرافی (خیلی قوی)',
      icon: Icons.security,
      length: 20,
      useUpper: true,
      useLower: true,
      useNumbers: true,
      useSpecial: true,
    ),
    PasswordProfile(
      id: 'custom',
      label: 'تنظیمات دستی (پیشرفته)',
      icon: Icons.tune,
      length: 16,
      useUpper: true,
      useLower: true,
      useNumbers: true,
      useSpecial: true,
    ),
  ];

  late PasswordProfile _selectedProfile;

  late double _length;
  late bool _useUpper;
  late bool _useLower;
  late bool _useNumbers;
  late bool _useSpecial;

  @override
  void initState() {
    super.initState();
    _loadVaultItems();
    _selectedProfile = _profiles[2];
    _applyProfile(_selectedProfile);
    _serviceController.addListener(() {
      if (_isSaveEnabled) {
        setState(() {
          _isSaveEnabled = false;
        });
      }
    });
  }

  Future<void> _loadVaultItems() async {
    final items = await _vaultRepo.fetchItems(widget.masterSecret);
    setState(() {
      _vaultItems = items;
    });
  }

  // پر کردن فرم با انتخاب آیتم
  void _loadItemToForm(VaultItem item) {
    setState(() {
      _editingId = item.id;
      _serviceController.text = item.serviceName;
      _usernameController.text = item.username ?? '';
      _length = item.length.toDouble();
      _isSaveEnabled = true;
    });
    _isSaveEnabled = true;
    Navigator.pop(context);
  }

  void _clearForm() {
    setState(() {
      _editingId = null;
      _serviceController.clear();
      _usernameController.clear();
      _generatedCode = "";
      _isSaveEnabled = false;
    });
  }

  Future<void> _saveToVault() async {
    final serviceName = _serviceController.text.trim();
    final username = _usernameController.text.trim();

    if (serviceName.isEmpty) return;

    // --- بخش جدید: بررسی تکراری بودن ---
    final isDuplicate = _vaultItems.any((item) {
      // ۱. اگر در حال ویرایش هستیم، خود این آیتم را نادیده بگیر
      if (_editingId != null && item.id == _editingId) {
        return false;
      }

      // ۲. مقایسه نام سرویس (بدون حساسیت به حروف بزرگ و کوچک)
      final bool nameMatches =
          item.serviceName.toLowerCase() == serviceName.toLowerCase();

      // ۳. مقایسه نام کاربری (چون ممکن است گوگل با دو ایمیل مختلف داشته باشیم)
      final String itemUser = item.username ?? '';
      final bool userMatches = itemUser.toLowerCase() == username.toLowerCase();

      return nameMatches && userMatches;
    });

    if (isDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('این سرویس قبلاً با همین نام کاربری ذخیره شده است!'),
          backgroundColor: Colors.red,
        ),
      );
      // توقف عملیات ذخیره
      return;
    }
    // ------------------------------------

    try {
      await _vaultRepo.saveItem(
        id: _editingId,
        masterSecret: widget.masterSecret,
        serviceName: serviceName,
        username: username.isNotEmpty ? username : null,
        profileId: _selectedProfile.id,
        length: _length.round(),
        options: {
          'useUpper': _useUpper,
          'useLower': _useLower,
          'useNumbers': _useNumbers,
          'useSpecial': _useSpecial,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _editingId == null ? 'سرویس ذخیره شد' : 'سرویس بروزرسانی شد',
            ),
            backgroundColor: _editingId == null ? Colors.green : Colors.orange,
          ),
        );
      }

      _loadVaultItems(); // رفرش لیست

      // اگر آیتم جدید بود، آیدی‌اش را ست می‌کنیم که اگر دوباره دکمه زده شد، آپدیت شود (نه اینسرت)
      // نکته: چون اینجا آیدی جدید را از سرور نگرفتیم، بهتر است دکمه را غیرفعال کنیم
      // یا لیست را دوباره لود کنیم تا آیدی درست ست شود.
      if (_editingId == null) {
        setState(() {
          _isSaveEnabled =
              false; // دکمه را غیرفعال می‌کنیم تا کاربر مجبور شود دوباره تولید کند یا سرویس جدید بسازد
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteItem(String id) async {
    await _vaultRepo.deleteItem(id);
    _loadVaultItems();
    if (_editingId == id) _clearForm();
  }

  void _applyProfile(PasswordProfile profile) {
    setState(() {
      _selectedProfile = profile;
      if (profile.id != 'custom') {
        _length = profile.length.toDouble();
        _useUpper = profile.useUpper;
        _useLower = profile.useLower;
        _useNumbers = profile.useNumbers;
        _useSpecial = profile.useSpecial;
      }
    });
  }

  void _switchToCustom() {
    if (_selectedProfile.id != 'custom') {
      setState(() {
        _selectedProfile = _profiles.firstWhere((p) => p.id == 'custom');
      });
    }
  }

  void _handleGenerate() {
    if (!_formKey.currentState!.validate()) return;
    if (!_useUpper && !_useLower && !_useNumbers && !_useSpecial) {
      setState(() => _generatedCode = "حداقل یک نوع کاراکتر لازم است");
      return;
    }

    final options = PasswordOptions(
      length: _length.round(),
      useUpper: _useUpper,
      useLower: _useLower,
      useNumbers: _useNumbers,
      useSpecial: _useSpecial,
    );

    try {
      final code = generateDerivedCode(
        widget.masterSecret,
        _serviceController.text.trim(),
        options,
      );
      setState(() {
        _generatedCode = code;
        _isSaveEnabled = true;
      });
      FocusScope.of(context).unfocus();
    } catch (e) {
      setState(() => _generatedCode = "خطا: $e");
    }
  }

  void _copyToClipboard() {
    if (_generatedCode.isEmpty || _generatedCode.startsWith("خطا")) return;
    Clipboard.setData(ClipboardData(text: _generatedCode));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('کپی شد!')));
  }

  Future<void> _handleLogout() async {
    // ۱. نمایش دیالوگ تایید
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('خروج از حساب'),
        content: const Text(
          'آیا مطمئن هستید که می‌خواهید خارج شوید؟\nبا خروج از حساب، رمز اصلی از حافظه موقت پاک می‌شود.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('خروج'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;
    final storage = StorageService();
    await storage.deleteMasterSecret();

    await Supabase.instance.client.auth.signOut();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تولیدکننده هوشمند رمز'),
        actions: [
          // دکمه "جدید"
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'رمز جدید',
            onPressed: _clearForm,
          ),
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Colors.redAccent,
            ), // رنگ قرمز برای تمایز
            tooltip: 'خروج از حساب',
            onPressed: _handleLogout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      endDrawer: Drawer(
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Center(
                child: Text(
                  'گاوصندوق سرویس‌ها',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
            ),
            Expanded(
              child: _vaultItems.isEmpty
                  ? const Center(child: Text('لیست خالی است'))
                  : ListView.builder(
                      itemCount: _vaultItems.length,
                      itemBuilder: (context, index) {
                        final item = _vaultItems[index];
                        return ListTile(
                          title: Text(
                            item.serviceName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: item.username != null
                              ? Text(item.username!)
                              : null,
                          selected: item.id == _editingId,
                          onTap: () => _loadItemToForm(item),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.grey),
                            onPressed: () => _deleteItem(item.id),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_editingId != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 16),
                  color: Colors.orange[100],
                  child: Row(
                    children: [
                      const Icon(Icons.edit, size: 16, color: Colors.orange),
                      const SizedBox(width: 8),
                      const Text(
                        'در حال ویرایش سرویس',
                        style: TextStyle(color: Colors.deepOrange),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _clearForm,
                        child: const Text('لغو'),
                      ),
                    ],
                  ),
                ),
              TextFormField(
                controller: _serviceController,
                decoration: InputDecoration(
                  labelText: 'نام سرویس (مثلاً بانک ملی)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.apps),
                ),
                validator: (v) => v!.isEmpty ? 'نام سرویس الزامی است' : null,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'نام کاربری (اختیاری)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<PasswordProfile>(
                initialValue: _selectedProfile,
                decoration: const InputDecoration(
                  labelText: 'نوع رمز مورد نیاز',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _profiles.map((profile) {
                  return DropdownMenuItem(
                    value: profile,
                    child: Row(
                      children: [
                        Icon(profile.icon, size: 18, color: Colors.grey[700]),
                        const SizedBox(width: 8),
                        Text(
                          profile.label,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) _applyProfile(value);
                },
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 0,
                color: Colors.grey[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text(
                            'طول رمز:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Text('${_length.round()} کاراکتر'),
                        ],
                      ),
                      Slider(
                        value: _length,
                        min: 4,
                        max: 32,
                        divisions: 28,
                        onChanged: (val) {
                          _switchToCustom();
                          setState(() => _length = val);
                        },
                      ),
                      const Divider(),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildChip('A-Z', _useUpper, (v) {
                            _switchToCustom();
                            setState(() => _useUpper = v);
                          }),
                          _buildChip('a-z', _useLower, (v) {
                            _switchToCustom();
                            setState(() => _useLower = v);
                          }),
                          _buildChip('0-9', _useNumbers, (v) {
                            _switchToCustom();
                            setState(() => _useNumbers = v);
                          }),
                          _buildChip('@#\$', _useSpecial, (v) {
                            _switchToCustom();
                            setState(() => _useSpecial = v);
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Row(
                children: [
                  // دکمه تولید رمز (سمت راست - یا چپ بسته به زبان)
                  Expanded(
                    flex: 3, // فضای بیشتری می‌گیرد
                    child: ElevatedButton.icon(
                      onPressed: _handleGenerate,
                      icon: const Icon(Icons.vpn_key),
                      label: const Text('تولید رمز'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        elevation: 2,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12), // فاصله بین دو دکمه
                  // دکمه ذخیره (سمت چپ)
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      // ۷. منطق غیرفعال‌سازی: اگر _isSaveEnabled فالس باشد، onPressed نال می‌شود (دکمه خاکستری)
                      onPressed: _isSaveEnabled ? _saveToVault : null,

                      icon: Icon(
                        _editingId != null ? Icons.save_as : Icons.save,
                      ),
                      label: Text(_editingId != null ? 'بروزرسانی' : 'ذخیره'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        // رنگ بر اساس حالت ویرایش/جدید
                        backgroundColor: _editingId != null
                            ? Colors.orange
                            : Colors.green,
                        foregroundColor: Colors.white,
                        // استایل دکمه غیرفعال
                        disabledBackgroundColor: Colors.grey[300],
                        disabledForegroundColor: Colors.grey[500],
                        elevation: _isSaveEnabled ? 2 : 0,
                      ),
                    ),
                  ),
                ],
              ),

              if (_generatedCode.isNotEmpty) ...[
                const SizedBox(height: 32),
                InkWell(
                  onTap: _copyToClipboard,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'رمز تولید شده (برای کپی ضربه بزنید)',
                          style: TextStyle(fontSize: 12, color: Colors.green),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _generatedCode,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, bool value, Function(bool) onChanged) {
    return FilterChip(
      label: Text(label),
      selected: value,
      onSelected: onChanged,
      showCheckmark: false,
      selectedColor: Colors.blue[100],
      labelStyle: TextStyle(
        color: value ? Colors.blue[900] : Colors.black54,
        fontWeight: value ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
