import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show ClipboardData, Clipboard;
import 'package:pass_generator/services/hash_gen.dart';

class PasswordGeneratorPage extends StatefulWidget {
  final String masterSecret;
  const PasswordGeneratorPage({super.key, required this.masterSecret});

  @override
  State<PasswordGeneratorPage> createState() => _PasswordGeneratorPageState();
}

class _PasswordGeneratorPageState extends State<PasswordGeneratorPage> {
  final _serviceController = TextEditingController();
  String _generatedCode = "";

  double _length = 16.0;
  bool _useUpper = true;
  bool _useLower = true;
  bool _useNumbers = true;
  bool _useSpecial = true;

  void _handleGenerate() {
    final master = widget.masterSecret;
    final service = _serviceController.text;

    if (service.isNotEmpty) {
      final options = PasswordOptions(
        length: _length.round(),
        useUpper: _useUpper,
        useLower: _useLower,
        useNumbers: _useNumbers,
        useSpecial: _useSpecial,
      );

      try {
        final code = generateDerivedCode(master, service, options);
        setState(() {
          _generatedCode = code;
        });
      } catch (e) {
        setState(() {
          print("error is $e");
          _generatedCode = "خطا: حداقل یک مجموعه کاراکتر انتخاب کنید.";
        });
      }
    }
  }

  void _copyToClipboard() {
    if (_generatedCode.isEmpty || _generatedCode.startsWith("خطا:")) return;
    Clipboard.setData(ClipboardData(text: _generatedCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('کد در کلیپ بورد کپی شد!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _serviceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Password Generator')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _serviceController,
                decoration: const InputDecoration(
                  labelText: 'نام سرویس (مثلاً: بانک ملی)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'تنظیمات رمز عبور',
                style: Theme.of(context).textTheme.titleMedium,
              ),

              Row(
                children: [
                  const Text('طول:'),
                  Expanded(
                    child: Slider(
                      value: _length,
                      min: 4,
                      max: 32,
                      divisions: 28,
                      label: _length.round().toString(),
                      onChanged: (double value) {
                        setState(() {
                          _length = value;
                        });
                      },
                    ),
                  ),
                  Text(
                    _length.round().toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              Wrap(
                spacing: 8.0,
                runSpacing: 0.0,
                children: [
                  CheckboxListTile(
                    title: const Text('A-Z'),
                    value: _useUpper,
                    onChanged: (bool? value) {
                      setState(() {
                        _useUpper = value ?? false;
                      });
                    },
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    title: const Text('a-z'),
                    value: _useLower,
                    onChanged: (bool? value) {
                      setState(() {
                        _useLower = value ?? false;
                      });
                    },
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    title: const Text('0-9'),
                    value: _useNumbers,
                    onChanged: (bool? value) {
                      setState(() {
                        _useNumbers = value ?? false;
                      });
                    },
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    title: const Text('#!%'),
                    value: _useSpecial,
                    onChanged: (bool? value) {
                      setState(() {
                        _useSpecial = value ?? false;
                      });
                    },
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _handleGenerate,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('تولید کد', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 32),

              if (_generatedCode.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'کد تولید شده:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            _generatedCode,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              color: _generatedCode.startsWith("خطا:")
                                  ? Colors.red
                                  : null,
                            ),
                            maxLines: 2,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded),
                          onPressed: _copyToClipboard,
                          tooltip: 'کپی در کلیپ‌بورد',
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
