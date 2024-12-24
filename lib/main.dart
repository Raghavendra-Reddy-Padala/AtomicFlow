import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:habit_tracker/backend/Habit_database.dart';
import 'package:habit_tracker/firebase_options.dart';
import 'package:habit_tracker/models/notes_state.dart';
import 'package:habit_tracker/models/pomodoro_state.dart';
import 'package:habit_tracker/pages/auth_page.dart';
import 'package:habit_tracker/pages/homepage.dart';
import 'package:habit_tracker/pages/loginpage.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        // Ensure HabitDatabase is initialized
        ChangeNotifierProvider(create: (_) => HabitDatabase()),
        ChangeNotifierProvider(create: (_) => PomodoroState()),
        ChangeNotifierProvider(create: (_) => NotesState()),
        ChangeNotifierProvider(create: (_) => AuthService()), // AuthService as ChangeNotifier
        StreamProvider<User?>(
          create: (_) => FirebaseAuth.instance.authStateChanges(),
          initialData: null,
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Tracker',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.green,
        scaffoldBackgroundColor: Colors.black,
        cardColor: Colors.grey[900],
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();

    if (user == null) {
      return const LoginPage();
    }

    // Ensure the ResponsiveHomePage is wrapped with all necessary providers
    return ChangeNotifierProvider<HabitDatabase>.value(
      value: context.read<HabitDatabase>(),
      child: const ResponsiveHomePage(),
    );
  }
}
