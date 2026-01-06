import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karma_split/pages/main_page.dart';
import 'pages/auth_choice_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kFirstLaunchKey = 'is_first_launch';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await dotenv.load(fileName: ".env");

  // Check if this is the first launch
  final prefs = await SharedPreferences.getInstance();
  final isFirstLaunch = prefs.getBool(_kFirstLaunchKey) ?? true;

  if (isFirstLaunch) {
    await prefs.setBool(_kFirstLaunchKey, false);
  }

  runApp(ProviderScope(child: MyApp(isFirstLaunch: isFirstLaunch)));
}

class AuthWrapper extends StatelessWidget {
  final bool isFirstLaunch;
  const AuthWrapper({super.key, this.isFirstLaunch = false});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show splash screen while checking auth state
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading...'),
                ],
              ),
            ),
          );
        }
        if (snapshot.hasData) {
          return const MainPage();
        } else {
          // On first launch, show AuthChoicePage regardless of auth state
          // On subsequent launches, also show AuthChoicePage when not logged in
          return const AuthChoicePage();
        }
      },
    );
  }

  // Static method to check if user is logged in
  static bool isUserLoggedIn() {
    return FirebaseAuth.instance.currentUser != null;
  }
}

class MyApp extends StatelessWidget {
  final bool isFirstLaunch;
  const MyApp({super.key, this.isFirstLaunch = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Karma Split',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        fontFamily: 'Roboto',
      ),
      home: AuthWrapper(isFirstLaunch: isFirstLaunch),
    );
  }
}
