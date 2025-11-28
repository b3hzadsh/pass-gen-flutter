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

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  void _checkStatus() async {
    if (await _storage.hasMasterSecret()) {
      _authenticateAndNavigate();
    } else {
      _navigateToSetup();
    }
  }

  void _authenticateAndNavigate() async {
    final isAuthenticated = await _bioService.authenticate(
      'برای دسترسی به برنامه احراز هویت کنید',
    );

    if (mounted && isAuthenticated) {
      final secret = await _storage.getMasterSecret();
      if (secret != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PasswordGeneratorPage(masterSecret: secret),
          ),
        );
      }
    } else {
      print("Authentication Failed");
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
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
