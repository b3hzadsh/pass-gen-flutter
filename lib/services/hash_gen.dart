import 'dart:convert';
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

  /// تعداد دسته‌های انتخاب شده را برمی‌گرداند
  int get selectedCategoriesCount {
    int count = 0;
    if (useUpper) count++;
    if (useLower) count++;
    if (useNumbers) count++;
    if (useSpecial) count++;
    return count;
  }

  /// ساخت رشته کاراکترهای مجاز با StringBuffer (بهینه‌تر)
  String buildCharset() {
    final buffer = StringBuffer();
    if (useUpper) buffer.write(_upper);
    if (useLower) buffer.write(_lower);
    if (useNumbers) buffer.write(_numbers);
    if (useSpecial) buffer.write(_special);
    return buffer.toString();
  }
}

String generateDerivedCode(
  String masterSecret,
  String serviceName,
  PasswordOptions options,
) {
  final allChars = options.buildCharset();
  if (allChars.isEmpty) {
    throw Exception('حداقل یک نوع کاراکتر باید انتخاب شود.');
  }
  if (options.length < options.selectedCategoriesCount) {
    // اختیاری: می‌توانید خطا دهید یا اجازه دهید کد کارش را بکند (که باعث حذف برخی شروط می‌شود)
    // throw Exception('طول رمز کمتر از تعداد دسته‌های انتخاب شده است.');
  }

  final keyBytes = utf8.encode(masterSecret);
  final messageBytes = utf8.encode(serviceName);
  final hmac = Hmac(sha256, keyBytes);
  final digest = hmac.convert(messageBytes);
  final hashBytes = digest.bytes; // این آرایه ۳۲ بایتی است

  final List<String> passwordChars = [];
  int byteIndex = 0;

  if (options.useUpper) {
    passwordChars.add(_pickChar(_upper, hashBytes, byteIndex++));
  }
  if (options.useLower) {
    passwordChars.add(_pickChar(_lower, hashBytes, byteIndex++));
  }
  if (options.useNumbers) {
    passwordChars.add(_pickChar(_numbers, hashBytes, byteIndex++));
  }
  if (options.useSpecial) {
    passwordChars.add(_pickChar(_special, hashBytes, byteIndex++));
  }

  while (passwordChars.length < options.length) {
    passwordChars.add(_pickChar(allChars, hashBytes, byteIndex++));
  }

  _deterministicShuffle(passwordChars, hashBytes, byteIndex);

  if (passwordChars.length > options.length) {
    return passwordChars.sublist(0, options.length).join('');
  }

  return passwordChars.join('');
}

String _pickChar(String source, List<int> hashBytes, int index) {
  final byte = hashBytes[index % hashBytes.length];
  return source[byte % source.length];
}

void _deterministicShuffle(List<String> list, List<int> hashBytes, int seedIndex) {
  for (int i = list.length - 1; i > 0; i--) {
    final byte = hashBytes[seedIndex % hashBytes.length];
    seedIndex++;
    
    final j = byte % (i + 1);
    final temp = list[i];
    list[i] = list[j];
    list[j] = temp;
  }
}

String hashString(String text) {
  final bytes = utf8.encode(text);
  final digest = sha256.convert(bytes);
  return digest.toString();
}