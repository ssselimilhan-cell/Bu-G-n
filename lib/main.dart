import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config.dart';
import 'screens/home_screen.dart';

const _brandOrange = Color(0xFFE97824);
const _brandBlue = Color(0xFF1268B3);
const _ink = Color(0xFF263B50);
const _page = Color(0xFFFFF0DF);
const _surface = Color(0xFFFFFAF4);
const _line = Color(0xFFF0D8C1);

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
    final scheme = ColorScheme.fromSeed(
      seedColor: _brandOrange,
      brightness: Brightness.light,
    ).copyWith(
      primary: _brandOrange,
      onPrimary: Colors.white,
      secondary: _brandBlue,
      onSecondary: Colors.white,
      tertiary: const Color(0xFF238C86),
      surface: _surface,
      onSurface: _ink,
    );

    return MaterialApp(
      title: 'BUGÜN',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: 'Roboto',
        colorScheme: scheme,
        scaffoldBackgroundColor: _page,
        appBarTheme: const AppBarTheme(
          backgroundColor: _page,
          foregroundColor: _ink,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: _ink,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        textTheme: const TextTheme(
          displaySmall: TextStyle(color: _ink, fontWeight: FontWeight.w800, height: 1.12),
          headlineMedium: TextStyle(color: _ink, fontWeight: FontWeight.w800, height: 1.15),
          titleLarge: TextStyle(color: _ink, fontWeight: FontWeight.w800, height: 1.2),
          titleMedium: TextStyle(color: _ink, fontWeight: FontWeight.w700, height: 1.25),
          bodyLarge: TextStyle(color: _ink, height: 1.4),
          bodyMedium: TextStyle(color: _ink, height: 1.35),
          labelLarge: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.1),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _brandOrange,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFE8CBB2),
            disabledForegroundColor: Colors.white,
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _surface,
            foregroundColor: _ink,
            elevation: 0,
            minimumSize: const Size(48, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: _line),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _ink,
            minimumSize: const Size(48, 46),
            side: const BorderSide(color: _line),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: _brandBlue,
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: _brandBlue,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: _surface,
          selectedColor: const Color(0xFFFFE1C2),
          checkmarkColor: _brandBlue,
          side: const BorderSide(color: _line),
          labelStyle: const TextStyle(color: _ink, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          hintStyle: const TextStyle(color: Color(0xFF8A8178)),
          labelStyle: const TextStyle(color: _ink),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _brandOrange, width: 1.7),
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? _brandOrange : null,
          ),
          trackColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? const Color(0xFFFFD0A3)
                : null,
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: _surface,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: const TextStyle(
            color: _ink,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: _surface,
          surfaceTintColor: Colors.transparent,
          showDragHandle: true,
          modalBackgroundColor: _surface,
        ),
        dividerTheme: const DividerThemeData(color: _line, thickness: 1, space: 1),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: _ink,
          contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: _surface,
          indicatorColor: const Color(0xFFFFE1C2),
          elevation: 0,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              color: states.contains(WidgetState.selected) ? _ink : const Color(0xFF77716C),
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w800
                  : FontWeight.w500,
            ),
          ),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(color: _brandOrange),
      ),
      home: const HomeScreen(),
    );
  }
}
