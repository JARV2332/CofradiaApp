class SupabaseConfig {
  /// En Vercel (Settings → Environment Variables) define `SUPABASE_URL` y `SUPABASE_ANON_KEY`
  /// para no depender solo de los valores por defecto del código.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://wtngrplmuehuabbdvtjb.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'sb_publishable_rL9ACkl0b1MCpIJaHPXthw__E0z_Cm9',
  );
}

