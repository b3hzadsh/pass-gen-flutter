import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vault_item.dart';
import '../services/crypto_service.dart';

class VaultRepository {
  final _supabase = Supabase.instance.client;

  Future<List<VaultItem>> fetchItems(String masterSecret) async {
    try {
      // ۱. دریافت داده خام
      final response = await _supabase
          .from('vault_items')
          .select()
          .order('created_at', ascending: false);

      print("DEBUG: تعداد آیتم‌های دریافتی از سرور: ${response.length}");

      final List<VaultItem> items = [];

      for (var row in response) {
        try {
          // ۲. تلاش برای رمزگشایی
          final decrypted = CryptoService.decryptData(
            row['encrypted_data'],
            masterSecret,
          );

          if (decrypted != null) {
            items.add(
              VaultItem(
                id: row['id'],
                serviceName: decrypted['serviceName'],
                username: decrypted['username'],
                profileId:
                    decrypted['profileId'] ??
                    'custom', // جلوگیری از کرش اگر نال بود
                length: decrypted['length'],
                options: Map<String, bool>.from(decrypted['options']),
              ),
            );
          } else {
            print("DEBUG: رمزگشایی آیتم ${row['id']} شکست خورد (null برگشت).");
          }
        } catch (e) {
          print("DEBUG: خطا در پارس کردن آیتم ${row['id']}: $e");
        }
      }
      return items;
    } catch (e) {
      print("DEBUG: خطا در ارتباط با Supabase: $e");
      return [];
    }
  }

  Future<void> saveItem({
    required String? id, // اگر نال باشد یعنی جدید، اگر باشد یعنی ادیت
    required String masterSecret,
    required String serviceName,
    String? username,
    required String profileId,
    required int length,
    required Map<String, bool> options,
  }) async {
    final userId = _supabase.auth.currentUser!.id;

    final dataMap = {
      'serviceName': serviceName,
      'username': username,
      'profileId': profileId,
      'length': length,
      'options': options,
    };

    final encrypted = CryptoService.encryptData(dataMap, masterSecret);

    if (id != null) {
      // Update
      await _supabase
          .from('vault_items')
          .update({'encrypted_data': encrypted})
          .eq('id', id);
    } else {
      // Insert
      await _supabase.from('vault_items').insert({
        'user_id': userId,
        'encrypted_data': encrypted,
      });
    }
  }

  Future<void> deleteItem(String id) async {
    await _supabase.from('vault_items').delete().eq('id', id);
  }
}
