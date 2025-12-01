import 'package:flutter/material.dart';
import 'package:pass_generator/pages/pass_gen_page.dart'
    show PasswordGeneratorPage;
import 'package:pass_generator/providers/secret_provider.dart'
    show SecretProvider;
import 'package:pass_generator/repository/user_text_repository.dart';
import 'package:pass_generator/services/hash_gen.dart' show hashString;
import 'package:pass_generator/services/storage_service.dart'
    show StorageService;
import 'package:provider/provider.dart';

class SetupSecretPage extends StatefulWidget {
  const SetupSecretPage({super.key});

  @override
  State<SetupSecretPage> createState() => _SetupSecretPageState();
}

class _SetupSecretPageState extends State<SetupSecretPage> {
  final _masterController = TextEditingController();
  final _storage = StorageService();
  final UserTextRepository _repo = UserTextRepository();

  String? _errorText;
  bool _isLoading = false;
  bool _isObscure = true;

  @override
  void dispose() {
    _masterController.dispose(); // جلوگیری از نشت حافظه
    super.dispose();
  }

  Future<void> _saveAndProceed() async {
    final secret = _masterController.text.trim();

    if (secret.isEmpty) {
      setState(() => _errorText = 'نوشتن رمز الزامی است');
      return;
    }

    setState(() {
      _errorText = null;
      _isLoading = true;
    });

    try {
      String inputHash = hashString(secret);
      final existingData = await _repo.getMyText();

      if (existingData != null) {
        if (existingData.hashedMasterSecret == inputHash) {
          await _storage.saveMasterSecret(secret);
        } else {
          setState(() {
            _errorText =
                'این رمز با رمز قبلی ذخیره شده شما در سرور مطابقت ندارد!';
            _isLoading = false;
          });
          return;
        }
      } else {
        await _repo.saveText(secret);
        await _storage.saveMasterSecret(secret);
      }
      if (mounted) {
        context.read<SecretProvider>().setSecret(secret);

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PasswordGeneratorPage(masterSecret: secret),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در برقراری ارتباط: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text('تنظیم رمز اصلی')),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security, size: 80, color: Colors.blueGrey),
              const SizedBox(height: 24),
              const Text(
                'این رمز بسیار مهم است و قابل بازیابی نیست.\nآن را امن نگه دارید.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 32),

              TextField(
                controller: _masterController,
                obscureText: _isObscure,
                decoration: InputDecoration(
                  labelText: 'رمز اصلی را وارد کنید',
                  border: const OutlineInputBorder(),
                  errorText: _errorText,
                  prefixIcon: const Icon(Icons.vpn_key),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isObscure = !_isObscure;
                      });
                    },
                  ),
                ),
                onChanged: (value) {
                  if (_errorText != null) {
                    setState(() => _errorText = null);
                  }
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAndProceed,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'ذخیره و ادامه',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
