import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

const String _upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
const String _lower = 'abcdefghijklmnopqrstuvwxyz';
const String _numbers = '0123456789';
const String _special = '!@#\$%^&*()-_=+';

class PasswordOptions {
  final int length;
  final bool useUpper;
  final bool useLower;
  final bool useNumbers;
  final bool useSpecial;

  const PasswordOptions({
    this.length = 16,
    this.useUpper = true,
    this.useLower = true,
    this.useNumbers = true,
    this.useSpecial = true,
  });

  String buildCharset() {
    String chars = '';
    if (useUpper) chars += _upper;
    if (useLower) chars += _lower;
    if (useNumbers) chars += _numbers;
    if (useSpecial) chars += _special;
    return chars;
  }

  List<String> getGuaranteedChars(List<int> hashBytes) {
    List<String> guaranteed = [];
    int byteIndex = 0;

    if (useUpper) {
      guaranteed.add(
        _upper[_getCharIndex(hashBytes, byteIndex++, _upper.length)],
      );
    }
    if (useLower) {
      guaranteed.add(
        _lower[_getCharIndex(hashBytes, byteIndex++, _lower.length)],
      );
    }
    if (useNumbers) {
      guaranteed.add(
        _numbers[_getCharIndex(hashBytes, byteIndex++, _numbers.length)],
      );
    }
    if (useSpecial) {
      guaranteed.add(
        _special[_getCharIndex(hashBytes, byteIndex++, _special.length)],
      );
    }
    return guaranteed;
  }
}

String generateDerivedCode(
  String masterSecret,
  String serviceName,
  PasswordOptions options,
) {
  var keyBytes = utf8.encode(masterSecret);
  var messageBytes = utf8.encode(serviceName);
  var hmacSha256 = Hmac(sha256, keyBytes);
  var digest = hmacSha256.convert(messageBytes);
  List<int> hashBytes = digest.bytes;

  String allChars = options.buildCharset();
  if (allChars.isEmpty) {
    throw Exception('No character sets selected');
  }

  List<String> guaranteedChars = options.getGuaranteedChars(hashBytes);

  List<String> passwordChars = [];

  passwordChars.addAll(guaranteedChars);

  int byteIndex = guaranteedChars.length;
  while (passwordChars.length < options.length) {
    passwordChars.add(
      allChars[_getCharIndex(hashBytes, byteIndex++, allChars.length)],
    );
  }

  var random = Random(_bytesToInt(hashBytes.sublist(16, 24)));
  passwordChars.shuffle(random);

  if (passwordChars.length > options.length) {
    passwordChars = passwordChars.sublist(0, options.length);
  }

  return passwordChars.join('');
}

int _getCharIndex(List<int> hashBytes, int byteIndex, int setLength) {
  return hashBytes[byteIndex % hashBytes.length] % setLength;
}

int _bytesToInt(List<int> bytes) {
  var data = ByteData.sublistView(Uint8List.fromList(bytes));
  return data.getInt64(0);
}
