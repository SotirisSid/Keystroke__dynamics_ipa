import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants.dart';

class MainPage extends StatelessWidget {
  final String userName;
  final List<String> predictions; // Ensure this is a list

  const MainPage({
    super.key,
    required this.userName,
    required this.predictions, // Keep it as a list
  });

  @override
  Widget build(BuildContext context) {
    // Create a message to display based on predictions
    String predictionMessage = '';
    if (predictions.isNotEmpty) {
      predictionMessage = predictions.join('\n'); // Join messages directly
    } else {
      predictionMessage = 'No predictions available.';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _logout(context);
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Add padding for better layout
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Welcome, $userName!', style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 20),
              Text(
                predictionMessage, // Display the prediction messages
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/train',
                    arguments: {
                      'userName': userName, // Wrap userName in a Map
                    },
                  );
                },
                child: const Text('Train Keystroke Dynamics'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _logout(BuildContext context) async {
    const FlutterSecureStorage storage = FlutterSecureStorage();

    // Retrieve the token from secure storage
    String? token = await storage.read(key: 'auth_token');

    print('Token to send: $token');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/logout'), // server URL
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization':
              token != null ? 'Bearer $token' : '', // Add the token here
        },
        body: jsonEncode(<String, dynamic>{
          // Optionally, you can send any necessary data in the body.
        }),
      );

      if (response.statusCode == 200) {
        // Logout successful, navigate back to the login page
        await storage.delete(key: 'auth_token');
        await storage.delete(key: 'isLoggedIn');
        await storage.delete(key: 'userName');
        await storage.delete(key: 'predictions');
        Navigator.pushReplacementNamed(
            context, '/'); // Ensure you have the correct route defined
        print('Logged out successfully');
      } else {
        // Handle error response
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        _showErrorDialog(context, responseData['message'] ?? 'Logout failed.');
      }
    } catch (e) {
      _showErrorDialog(context, 'An error occurred: $e');
    }
  }

  // Helper function to show error dialog
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _trainKeystrokeDynamics() {
    // Implement your training logic here
    print(
        'Training keystroke dynamics...'); // Placeholder for training functionality
  }
}
