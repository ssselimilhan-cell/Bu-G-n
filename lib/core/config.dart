class AppConfig {
  // Supabase project URL. The client URL must be the project root,
  // not the REST endpoint (/rest/v1/).
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://yvshqvethzbwcgpqaptd.supabase.co',
  );

  // Supabase publishable key. This key is intended for client applications.
  // A dart-define can override it for other environments.
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'sb_publishable_OEVkps-n_bkL2ykgC1oS_A_A_WK3ppN',
  );
}
