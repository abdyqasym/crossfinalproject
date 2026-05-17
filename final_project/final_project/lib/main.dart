import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    // Requirement: Riverpod ProviderScope wraps entire app
    const ProviderScope(child: AutoVaultApp()),
  );
}

class AutoVaultApp extends ConsumerWidget {
  const AutoVaultApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'AutoVault',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// THEME  —  Luxury automotive dark palette with warm gold accents
// ─────────────────────────────────────────────────────────────
abstract class AppTheme {
  // Palette
  static const Color bg         = Color(0xFF0D0D0D);
  static const Color surface    = Color(0xFF161616);
  static const Color card       = Color(0xFF1D1D1D);
  static const Color divider    = Color(0xFF2C2C2C);

  static const Color gold       = Color(0xFFC8A951);
  static const Color goldLight  = Color(0xFFE2C97E);
  static const Color goldDark   = Color(0xFF9A7B30);

  static const Color textHigh   = Color(0xFFF2F2F2);
  static const Color textMed    = Color(0xFF8A8A8A);
  static const Color textLow    = Color(0xFF4A4A4A);

  static const Color green      = Color(0xFF4CAF76);
  static const Color red        = Color(0xFFE05252);

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.dark(
      primary: gold,
      onPrimary: Colors.black,
      secondary: goldLight,
      surface: surface,
      error: red,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: textHigh),
      titleTextStyle: TextStyle(
        color: textHigh,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: card,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: gold, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: red, width: 1.5),
      ),
      labelStyle: const TextStyle(color: textMed, fontSize: 14),
      hintStyle:  const TextStyle(color: textLow,  fontSize: 14),
      errorStyle: const TextStyle(color: red,       fontSize: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: gold,
        foregroundColor: Colors.black,
        disabledBackgroundColor: goldDark.withOpacity(0.35),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 17),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 14,
          letterSpacing: 1.5,
        ),
      ),
    ),
    dividerTheme: const DividerThemeData(color: divider, thickness: 1),
  );
}