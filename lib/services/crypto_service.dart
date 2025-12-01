import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

class CryptoService {
  // تبدیل Master Secret به کلید ۳۲ بایتی و IV ۱۶ بایتی
  static enc.Key _deriveKey(String masterSecret) {
    // از هش SHA256 رمز اصلی به عنوان کلید استفاده می‌کنیم
    final bytes = utf8.encode(masterSecret);
    final digest = sha256.convert(bytes);
    return enc.Key(Uint8List.fromList(digest.bytes));
  }

  static enc.IV _deriveIV(String masterSecret) {
    // از ۱۶ بایت اول هش به عنوان IV استفاده می‌کنیم (برای قطعی بودن)
    final bytes = utf8.encode(masterSecret);
    final digest = sha256.convert(bytes);
    return enc.IV(Uint8List.fromList(digest.bytes.sublist(0, 16)));
  }

  static String encryptData(Map<String, dynamic> data, String masterSecret) {
    final key = _deriveKey(masterSecret);
    final iv = _deriveIV(masterSecret);

    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

    final jsonString = jsonEncode(data);
    final encrypted = encrypter.encrypt(jsonString, iv: iv);

    return encrypted.base64;
  }

  static Map<String, dynamic>? decryptData(
    String encryptedBase64,
    String masterSecret,
  ) {
    try {
      final key = _deriveKey(masterSecret);
      final iv = _deriveIV(masterSecret);

      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

      final decrypted = encrypter.decrypt64(encryptedBase64, iv: iv);
      return jsonDecode(decrypted) as Map<String, dynamic>;
    } catch (e) {
      print("Decryption failed: $e");
      return null;
    }
  }
}
