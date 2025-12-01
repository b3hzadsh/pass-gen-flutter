import 'package:pass_generator/models/user_text_model.dart'
    show UserPrivateText;
import 'package:pass_generator/services/hash_gen.dart' show hashString;
import 'package:supabase_flutter/supabase_flutter.dart';

class UserTextRepository {
  final SupabaseClient _supabase;

  UserTextRepository({SupabaseClient? client})
    : _supabase = client ?? Supabase.instance.client;
  static const String _tableName = 'user_private_texts';
  static const String _colUserId = 'user_id';
  static const String _colContent = 'text_content';
  static const String _colUpdatedAt = 'updated_at';

  Future<void> saveText(String rawContent) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('کاربر وارد نشده است');
    }
    final hashedContent = hashString(rawContent);

    try {
      await _supabase.from(_tableName).upsert({
        _colUserId: user.id,
        _colContent: hashedContent,
        _colUpdatedAt: DateTime.now().toUtc().toIso8601String(),
      }, onConflict: _colUserId);
    } on PostgrestException catch (e) {
      throw Exception('خطا در ذخیره اطلاعات: ${e.message}');
    } catch (e) {
      throw Exception('خطای ناشناخته در ذخیره‌سازی');
    }
  }

  Future<UserPrivateText?> getMyText() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq(_colUserId, user.id)
          .maybeSingle();

      if (response == null) return null;

      return UserPrivateText.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> deleteText() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      await _supabase.from(_tableName).delete().eq(_colUserId, user.id);
      return true;
    } catch (e) {
      return false;
    }
  }
}
