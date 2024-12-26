import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/firebase_options.dart';
import 'package:habit_tracker/screens/Profile_setup_screen.dart';
import 'package:habit_tracker/screens/login_screen.dart';
import 'package:habit_tracker/screens/signup_screen.dart';
import 'package:habit_tracker/services/databaseservice.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

final themeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

void main() {
  // Make zone errors fatal during development
  BindingBase.debugZoneErrorsAreFatal = true;

  // Create a single zone for all async operations
  runZoned(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    
    runApp(
      const ProviderScope(
        child: MyApp(),
      ),
    );
  });
}

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final firestoreService = ref.read(firestoreServiceProvider);

    // Call createRequiredIndexes()
    firestoreService.createRequiredIndexes();
    
    return MaterialApp(
      title: 'Habit Tracker',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      home: StreamBuilder(
        stream: ref.read(authServiceProvider).authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            return const HomeScreen();
          }

          return const LoginScreen();
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/profile-setup': (context) => const ProfileSetupScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}