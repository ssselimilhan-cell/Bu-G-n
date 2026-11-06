class AppConfig {
  // The isolated test APK is compiled with BUGUN_ISOLATED_TEST_BUILD=true.
  // Its client is deliberately pointed at loopback, never at the production project.
  static const bool isolatedTestBuild = bool.fromEnvironment(
    'BUGUN_ISOLATED_TEST_BUILD',
    defaultValue: false,
  );

  static const String supabaseUrl = isolatedTestBuild
      ? 'http://127.0.0.1:54321'
      : String.fromEnvironment(
          'SUPABASE_URL',
          defaultValue: 'https://yvshqvethzbwcgpqaptd.supabase.co',
        );

  static const String supabaseAnonKey = isolatedTestBuild
      ? 'offline-test-no-key'
      : String.fromEnvironment(
          'SUPABASE_ANON_KEY',
          defaultValue: 'sb_publishable_OEVkps-n_bkL2ykgC1oS_A_A_WK3ppN',
        );
}
