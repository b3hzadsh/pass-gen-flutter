import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pass_generator/repository/user_text_repository.dart';
import 'package:pass_generator/services/storage_service.dart';
import 'package:pass_generator/services/supabase_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  Future<void> _nativeGoogleLogin() async {
    setState(() => _isLoading = true);

    try {
      await SupabaseService.instance.nativeGoogleSignIn();
      if (!mounted) return;
      final storage = StorageService();
      UserTextRepository repo = UserTextRepository();

      final userText = await repo.getMyText();
      if (userText != null) {
        await storage.saveHashedMasterSecret(userText.hashedMasterSecret);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ورود با موفقیت انجام شد'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Login Error: $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 80,
                color: Colors.indigo,
              ),
              const SizedBox(height: 40),

              _isLoading
                  ? const CircularProgressIndicator()
                  : _buildStandardGoogleButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStandardGoogleButton() {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _nativeGoogleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.grey[200],
          elevation: 2,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FaIcon(
              FontAwesomeIcons.google,
              color: Color(0xFFDB4437),
              size: 20,
            ),
            const SizedBox(width: 12),
            const Text(
              'ورود با گوگل',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Roboto',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
