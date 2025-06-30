import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'providers/router_provider.dart';
import 'constants/app_constants.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure URL strategy for web
  usePathUrlStrategy();
  
  // Initialize Firebase
  await Firebase.initializeApp(
       options: DefaultFirebaseOptions.currentPlatform,
     );
  
  runApp(
    const ProviderScope(
      child: AmazonCloneApp(),
    ),
  );
}

class AmazonCloneApp extends ConsumerWidget {
  const AmazonCloneApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      darkTheme: _buildTheme(), // Use light theme for dark mode too
      themeMode: ThemeMode.light, // Force light theme always
      routerConfig: router,
    );
  }

  /// Build light theme
  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: Colors.white,
        background: const Color(0xFFF5F5F5),
        onSurface: Colors.black87,
        onBackground: Colors.black87,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      cardColor: Colors.white,
      fontFamily: 'AmazonEmber',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: 'AmazonEmber',
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: Colors.black87, fontSize: 32, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: Colors.black87, fontSize: 28, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(color: Colors.black87, fontSize: 24, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: Colors.black87, fontSize: 22, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.normal),
        bodyMedium: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.normal),
        bodySmall: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.normal),
        labelLarge: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500),
        labelMedium: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w500),
        labelSmall: TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }
}
