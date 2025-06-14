import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/add_income_screen.dart';
import 'screens/add_expense_screen.dart';
import 'screens/reports_screen.dart'; // Make sure this is at the top


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = false;

  void toggleDarkMode() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Finance Manager',
      debugShowCheckedModeBanner: false,
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: AuthWrapper(
        isDarkMode: isDarkMode,
        toggleDarkMode: toggleDarkMode,
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => HomeScreen(
          isDarkMode: isDarkMode,
          toggleDarkMode: toggleDarkMode,
        ),
        '/add_income': (context) => const AddIncomeScreen(),
        '/add_expense': (context) => const AddExpenseScreen(),
        '/reports': (context) => const ReportsScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback toggleDarkMode;

  const AuthWrapper({
    super.key,
    required this.isDarkMode,
    required this.toggleDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user != null) {
          return HomeScreen(
            isDarkMode: isDarkMode,
            toggleDarkMode: toggleDarkMode,
          );
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
