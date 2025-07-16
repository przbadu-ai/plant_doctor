import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';
import 'providers/app_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'screens/chats_list_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/debug_screen.dart';
import 'services/secure_config_service.dart';
import 'config/app_theme.dart';

void main() async {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize Firebase
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      // Set up Crashlytics
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      
      // Enable crash collection in debug mode (optional)
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    } catch (e) {
      print('Firebase initialization error: $e');
      // Continue without Firebase if initialization fails
    }
    
    // Load any saved tokens
    await SecureConfigService().loadToken();
    
    runApp(const MyApp());
  }, (error, stack) {
    // Catch any errors that occur outside of Flutter
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProxyProvider<LanguageProvider, AppProvider>(
          create: (_) => AppProvider(),
          update: (context, languageProvider, appProvider) {
            appProvider?.setLanguageProvider(languageProvider);
            return appProvider ?? AppProvider();
          },
        ),
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, langProvider, child) {
          return MaterialApp(
            title: langProvider.appTitle,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const ChatsListScreen(),
            routes: {
              '/settings': (context) => const SettingsScreen(),
              '/debug': (context) => const DebugScreen(),
            },
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}