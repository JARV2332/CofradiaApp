import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    await _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Incluye intento de refresco por si la sesión aún no está en memoria (p. ej. web al arrancar).
  Future<bool> isLoggedIn() async {
    if (_client.auth.currentSession != null) return true;
    try {
      final res = await _client.auth.refreshSession();
      return res.session != null;
    } catch (_) {
      return false;
    }
  }
}
