import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  final _storage = const FlutterSecureStorage();
  static const _masterKey = 'master_secret';

  Future<void> saveMasterSecret(String secret) async {
    await _storage.write(key: _masterKey, value: secret);
  }

  Future<String?> getMasterSecret() async {
    return await _storage.read(key: _masterKey);
  }

  Future<bool> hasMasterSecret() async {
    final secret = await getMasterSecret();
    return secret != null && secret.isNotEmpty;
  }
}
