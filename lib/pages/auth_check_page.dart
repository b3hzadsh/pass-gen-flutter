import 'package:flutter/material.dart';
import 'package:pass_generator/pages/pass_gen_page.dart'
    show PasswordGeneratorPage;
import 'package:pass_generator/pages/setup_secret_page.dart'
    show SetupSecretPage;
import 'package:pass_generator/services/biometric_service.dart'
    show BiometricService;
import 'package:pass_generator/services/storage_service.dart';

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  final _storage = StorageService();
  final _bioService = BiometricService();
  bool _isAuthFailed = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkStatus();
    });
  }

  Future<void> _checkStatus() async {
    try {
      final hasSecret = await _storage.hasMasterSecret();
      if (!mounted) return;
      if (hasSecret) {
        await _authenticateAndNavigate();
      } else {
        _navigateToSetup();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isAuthFailed = true;
      });
    }
  }

  Future<void> _authenticateAndNavigate() async {
    setState(() {
      _isLoading = true;
      _isAuthFailed = false;
    });

    final isAuthenticated = await _bioService.authenticate(
      'برای دسترسی به رمزها، هویت خود را تایید کنید',
    );

    if (!mounted) return;

    if (isAuthenticated) {
      final secret = await _storage.getMasterSecret();

      if (secret != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PasswordGeneratorPage(masterSecret: secret),
          ),
        );
      } else {
        _navigateToSetup();
      }
    } else {
      setState(() {
        _isLoading = false;
        _isAuthFailed = true;
      });
    }
  }

  void _navigateToSetup() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const SetupSecretPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_person_rounded, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            if (_isLoading) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('در حال بررسی امنیتی...'),
            ] else if (_isAuthFailed) ...[
              const Text(
                'احراز هویت انجام نشد',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _authenticateAndNavigate,
                icon: const Icon(Icons.fingerprint),
                label: const Text('تلاش مجدد'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
