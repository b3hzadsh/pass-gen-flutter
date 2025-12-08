import 'package:flutter_dotenv/flutter_dotenv.dart' show dotenv;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pass_generator/main.dart' show supabase;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();
  static SupabaseService get instance => _instance;
  final SupabaseClient _client = Supabase.instance.client;
  SupabaseClient get client => _client;


  Future<List<Map<String, dynamic>>> getAll(String table) async {
    try {
      final response = await _client.from(table).select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching data from $table: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getById(String table, int id) async {
    try {
      final response = await _client
          .from(table)
          .select()
          .eq('id', id)
          .maybeSingle(); // اگر پیدا نشد null برمی‌گرداند (به جای ارور)
      return response;
    } catch (e) {
      debugPrint('Error fetching row $id from $table: $e');
      return null;
    }
  }

  Future<void> insert(String table, Map<String, dynamic> data) async {
    try {
      await _client.from(table).insert(data);
    } catch (e) {
      debugPrint('Error inserting into $table: $e');
      rethrow;
    }
  }

  Future<void> update(String table, int id, Map<String, dynamic> data) async {
    try {
      await _client.from(table).update(data).eq('id', id);
    } catch (e) {
      debugPrint('Error updating row $id in $table: $e');
      rethrow;
    }
  }

  Future<void> delete(String table, int id) async {
    try {
      await _client.from(table).delete().eq('id', id);
    } catch (e) {
      debugPrint('Error deleting row $id from $table: $e');
      rethrow;
    }
  }

  User? get currentUser => _client.auth.currentUser;

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<bool> webGoogleSignIn() async {
    /// if client is web.
    return supabase.auth
        .signInWithOAuth(OAuthProvider.google)
        .then((value) {
          return true;
        })
        .catchError((error) {
          debugPrint('Error during Google sign-in: $error');
          return false;
        });
  }

  Future<AuthResponse> nativeGoogleSignIn() async {
    final webClientId = dotenv.env['WEB_CLIENT_ID'] ?? '';
    final androidClientId = dotenv.env['ANDROID_CLIENT_ID'] ?? '';
    final GoogleSignIn signIn = GoogleSignIn.instance;

    await signIn.initialize(
      // clientId: androidClientId, don't need this line, it find it with pakcage name and stuff
      serverClientId: webClientId,
    );

    final googleAccount = await signIn.authenticate();
    final googleAuthorization = await googleAccount.authorizationClient
        .authorizationForScopes(['email', 'profile']);
    final googleAuthentication = googleAccount.authentication;
    final idToken = googleAuthentication.idToken;
    final accessToken = googleAuthorization!.accessToken;

    if (idToken == null) {
      throw 'No ID Token found.';
    }

    return supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }
}
