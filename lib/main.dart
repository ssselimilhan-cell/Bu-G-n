import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: AppConfig.supabaseUrl, anonKey: AppConfig.supabaseAnonKey);
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        fontFamily: 'Arial',
      ),
      home: const HomeScreen(),
    );
  }
}
