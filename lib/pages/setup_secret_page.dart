import 'package:flutter/material.dart';
import 'package:pass_generator/pages/pass_gen_page.dart'
    show PasswordGeneratorPage;
import 'package:pass_generator/services/storage_service.dart'
    show StorageService;

class SetupSecretPage extends StatefulWidget {
  const SetupSecretPage({super.key});

  @override
  State<SetupSecretPage> createState() => _SetupSecretPageState();
}

class _SetupSecretPageState extends State<SetupSecretPage> {
  final _masterController = TextEditingController();
  final _storage = StorageService();

  void _saveAndProceed() async {
    final secret = _masterController.text;
    if (secret.isEmpty) return;

    await _storage.saveMasterSecret(secret);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => PasswordGeneratorPage(masterSecret: secret),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تنظیم رمز اصلی (فقط یکبار)')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'این رمز بسیار مهم است و قابل بازیابی نیست. آن را امن نگه دارید.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _masterController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'رمز اصلی را وارد کنید',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveAndProceed,
              child: const Text('ذخیره و ورود'),
            ),
          ],
        ),
      ),
    );
  }
}
