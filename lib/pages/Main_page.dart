import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants.dart';

class MainPage extends StatelessWidget {
  final String userName;
  final List<String> predictions;

  const MainPage({
    super.key,
    required this.userName,
    required this.predictions,
  });

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Welcome, $userName!', style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/train',
                    arguments: {
                      'userName': userName,
                    },
                  );
                },
                child: const Text('Train Keystroke Dynamics'),
              ),
              const SizedBox(height: 20),
              predictions.isNotEmpty
                  ? Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          children: predictions.map((prediction) {
                            return Card(
                              color:
                                  Colors.blue.shade50, // Light background color
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                leading: Icon(Icons.check_circle,
                                    color: Colors.blue),
                                title: Text(
                                  prediction,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    )
                  : Text(
                      'No predictions available.',
                      style:
                          const TextStyle(fontSize: 16, color: Colors.black54),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  void _logout(BuildContext context) async {
    const FlutterSecureStorage storage = FlutterSecureStorage();
    String? token = await storage.read(key: 'auth_token');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': token != null ? 'Bearer $token' : '',
        },
      );

      if (response.statusCode == 200) {
        await storage.deleteAll();
        Navigator.pushReplacementNamed(context, '/');
        print('Logged out successfully');
      } else {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        _showErrorDialog(context, responseData['message'] ?? 'Logout failed.');
      }
    } catch (e) {
      _showErrorDialog(context, 'An error occurred: $e');
    }
  }

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
}
