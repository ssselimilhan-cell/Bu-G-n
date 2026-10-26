import 'package:flutter/material.dart';
import 'screens/diyarbakir_draft_preview_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DiyarbakirDraftPreviewApp());
}

class DiyarbakirDraftPreviewApp extends StatelessWidget {
  const DiyarbakirDraftPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BUGÜN - Diyarbakır Test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF174F80)),
        scaffoldBackgroundColor: const Color(0xFFF7F7F5),
      ),
      home: const DiyarbakirDraftPreviewScreen(),
    );
  }
}