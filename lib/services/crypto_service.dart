import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'dart:typed_data';

class CryptoService {
  // این متد دقیقا معادل deriveKeyAndIV در جاوااسکریپت است
  static List<dynamic> _deriveKeyAndIV(String masterSecret) {
    // ۱. هش SHA256 از رمز اصلی
    final bytes = utf8.encode(masterSecret);
    final digest = sha256.convert(bytes);

    // ۲. کلید = ۳۲ بایت کامل هش
    final key = enc.Key(Uint8List.fromList(digest.bytes));

    // ۳. آی‌وی = ۱۶ بایت اول هش
    final iv = enc.IV(Uint8List.fromList(digest.bytes.sublist(0, 16)));

    return [key, iv];
  }

  static String encryptData(Map<String, dynamic> data, String masterSecret) {
    final params = _deriveKeyAndIV(masterSecret);
    final key = params[0] as enc.Key;
    final iv = params[1] as enc.IV;

    final encrypter = enc.Encrypter(
      enc.AES(key, mode: enc.AESMode.cbc, padding: 'PKCS7'),
    );

    final jsonString = jsonEncode(data);
    final encrypted = encrypter.encrypt(jsonString, iv: iv);

    return encrypted.base64;
  }

  static Map<String, dynamic>? decryptData(
    String encryptedBase64,
    String masterSecret,
  ) {
    try {
      final params = _deriveKeyAndIV(masterSecret);
      final key = params[0] as enc.Key;
      final iv = params[1] as enc.IV;

      final encrypter = enc.Encrypter(
        enc.AES(key, mode: enc.AESMode.cbc, padding: 'PKCS7'),
      );

      final decrypted = encrypter.decrypt64(encryptedBase64, iv: iv);
      return jsonDecode(decrypted) as Map<String, dynamic>;
    } catch (e) {
      // اگر رمز اشتباه باشد یا فرمت نخواند
      return null;
    }
  }
}
