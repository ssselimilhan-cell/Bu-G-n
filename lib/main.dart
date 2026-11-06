import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('tr_TR', null);

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabaseAnonKey,
  );

  runApp(const BugunApp());
}

class BugunApp extends StatelessWidget {
  const BugunApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BUGÜN',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF7F7F5),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1268B3),
          brightness: Brightness.light,
        ).copyWith(
          secondary: const Color(0xFFFF8A3D),
          tertiary: const Color(0xFF20A6A0),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}