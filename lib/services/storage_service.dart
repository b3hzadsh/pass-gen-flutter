import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  AndroidOptions _getAndroidOptions() =>
      const AndroidOptions(encryptedSharedPreferences: true);
  late final FlutterSecureStorage _storage;

  StorageService() {
    _storage = FlutterSecureStorage(aOptions: _getAndroidOptions());
  }

  static const _masterKey = 'master_secret';
  static const _hashedMasterKey = 'hashed_master_secret';

  Future<void> saveMasterSecret(String secret) async {
    try {
      await _storage.write(key: _masterKey, value: secret);
    } catch (e) {
      debugPrint('Error saving master secret: $e');
      throw Exception('Could not save secret securely');
    }
  }

  Future<String?> getMasterSecret() async {
    try {
      return await _storage.read(key: _masterKey);
    } catch (e) {
      debugPrint('Error reading master secret: $e');
      return null;
    }
  }

  Future<bool> hasMasterSecret() async {
    try {
      return await _storage.containsKey(key: _masterKey);
    } catch (e) {
      return false;
    }
  }

  Future<void> saveHashedMasterSecret(String secret) async {
    try {
      await _storage.write(key: _hashedMasterKey, value: secret);
    } catch (e) {
      debugPrint('Error saving hashed secret: $e');
    }
  }

  Future<String?> getHashedMasterSecret() async {
    return await _storage.read(key: _hashedMasterKey);
  }

  Future<bool> hasHashedMasterSecret() async {
    return await _storage.containsKey(key: _hashedMasterKey);
  }

  // todo impl logout and use this
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      debugPrint('Error clearing storage: $e');
    }
  }

  // یا پاک کردن تکی
  Future<void> deleteMasterSecret() async {
    await _storage.delete(key: _masterKey);
  }
}
