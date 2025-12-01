import 'package:flutter/material.dart';

class SecretProvider extends ChangeNotifier {
  String? _masterSecret;

  String? get masterSecret => _masterSecret;
  void setSecret(String secret) {
    _masterSecret = secret;
    notifyListeners();
  }

  void clearSecret() {
    _masterSecret = null;
    notifyListeners();
  }
}
