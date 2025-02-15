import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Import secure storage
import 'package:keystrokedynamics/pages/login_home_page.dart';
import 'pages/signup_page.dart';
import 'pages/main_page.dart';
import 'pages/train_keystroke_page.dart';
import 'pages/admin_page.dart';

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
        '/admin': (context) => AdminPage() // Admin page route
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
    // Retrieve login status from secure storage
    String? isLoggedIn = await _storage.read(key: 'isLoggedIn');

    if (isLoggedIn == 'true') {
      // If user is logged in, retrieve user information
      String? userName = await _storage.read(key: 'userName');
      String? role =
          await _storage.read(key: 'role'); // Retrieve role from storage

      // Retrieve and decode predictions JSON string
      String? predictionsString = await _storage.read(key: 'predictions');
      List<String> predictions = [];
      if (predictionsString != null && predictionsString.isNotEmpty) {
        predictions =
            List<String>.from(jsonDecode(predictionsString) as List<dynamic>);
      }

      // Check the role and navigate accordingly
      if (role == 'admin') {
        // Navigate to AdminPage if role is admin
        Navigator.pushReplacementNamed(context, '/admin', arguments: {
          'userName': userName,
          'predictions': predictions,
        });
      } else {
        // Navigate to MainPage for regular users
        Navigator.pushReplacementNamed(context, '/mainpage', arguments: {
          'userName': userName,
          'predictions': predictions,
        });
      }
    } else {
      // If user is not logged in, redirect to login page
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(); // Empty container while checking the login status
  }
}
