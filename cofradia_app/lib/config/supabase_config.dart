class SupabaseConfig {
  /// En Vercel (Settings → Environment Variables) define `SUPABASE_URL` y `SUPABASE_ANON_KEY`
  /// para no depender solo de los valores por defecto del código.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://iypgmitowoyjlumxogwv.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_2A8WZaOaGbYBND4AfD2bng_oloHkDRA',
  );
}

