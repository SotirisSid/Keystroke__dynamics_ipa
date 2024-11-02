import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Import secure storage
import 'package:keystrokedynamics/pages/login_home_page.dart';
import 'pages/signup_page.dart';
import 'pages/main_page.dart';
import 'pages/train_keystroke_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Keystroke Dynamics',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const CheckAuthState(), // Use CheckAuthState as the home widget
      routes: {
        '/login': (context) => const LoginHomePage(), // Login page route
        '/signup': (context) => const SignupPage(),
        '/mainpage': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return MainPage(
            userName: args['userName'],
            predictions: args['predictions'], // Correctly access predictions
          );
        },
        '/train': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return TrainKeystrokePage(
            userName: args['userName'], // Extract userName from the Map
          );
        },
      },
    );
  }
}

class CheckAuthState extends StatefulWidget {
  const CheckAuthState({super.key});

  @override
  _CheckAuthStateState createState() => _CheckAuthStateState();
}

class _CheckAuthStateState extends State<CheckAuthState> {
  static const _storage =
      FlutterSecureStorage(); // Create secure storage instance

  @override
  void initState() {
    super.initState();
    _checkLoginStatus(); // Check login status when the app starts
  }

  Future<void> _checkLoginStatus() async {
    String? isLoggedIn = await _storage.read(key: 'isLoggedIn');

    if (isLoggedIn == 'true') {
      // User is logged in, navigate to MainPage
      String? userName = await _storage.read(key: 'userName');
      // Decode predictions JSON string back into a list
      String? predictionsString = await _storage.read(key: 'predictions');
      List<String> predictions = [];
      if (predictionsString != null && predictionsString.isNotEmpty) {
        predictions =
            List<String>.from(jsonDecode(predictionsString) as List<dynamic>);
      }

      Navigator.pushReplacementNamed(context, '/mainpage', arguments: {
        'userName': userName,
        'predictions': predictions,
      });
    } else {
      // User is not logged in, navigate to the /login route
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(); // Empty container while checking the login status
  }
}
