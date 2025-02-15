import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final TextEditingController _entryLimitController = TextEditingController();
  final TextEditingController _userIdController = TextEditingController();
  void _logout(BuildContext context) async {
    const FlutterSecureStorage storage = FlutterSecureStorage();
    String? token = await storage.read(key: 'auth_token');
    print('Token to send: $token');

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
        final responseData = jsonDecode(response.body);
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

  void _evaluateMetrics(BuildContext context) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/evaluate-metrics'),
        headers: {
          'Authorization':
              'Bearer ${await FlutterSecureStorage().read(key: "auth_token")}'
        },
      );

      if (response.statusCode == 200) {
        final metrics = jsonDecode(response.body);
        _showMetricsDialog(context, metrics);
      } else {
        final responseData = jsonDecode(response.body);
        _showErrorDialog(
            context, responseData['message'] ?? 'Evaluation failed.');
      }
    } catch (e) {
      _showErrorDialog(context, 'An error occurred: $e');
    }
  }

  void _getUserDataCount(BuildContext context) async {
    final String userId = _userIdController.text;

    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a user ID or username')),
      );
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/user_data_count?user_id=$userId'),
        headers: {
          'Authorization':
              'Bearer ${await FlutterSecureStorage().read(key: "auth_token")}'
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final int dataCount = data['data_count'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User has $dataCount data entries')),
        );
      } else {
        final responseData = jsonDecode(response.body);
        _showErrorDialog(context,
            responseData['message'] ?? 'Failed to get user data count.');
      }
    } catch (e) {
      _showErrorDialog(context, 'An error occurred: $e');
    }
  }

  void _showMetricsDialog(BuildContext context, Map<String, dynamic> metrics) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Metrics Evaluation'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: metrics.entries.map((modelEntry) {
                String modelName = modelEntry.key;
                Map<String, dynamic> modelMetrics = modelEntry.value;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            modelName,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          ...modelMetrics.entries.map((metricEntry) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    metricEntry.key,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    metricEntry.value.toString(),
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  SizedBox(height: 8),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
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

  // Define the _showResetConfirmationDialog method
  void _showResetConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Reset'),
          content: Text(
              'Are you sure you want to reset the database? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                // Close the dialog without taking any action
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _resetDatabase(context); // Call the reset database function
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _trainModel(BuildContext context) async {
    const String url = '$baseUrl/train_model';

    final String maxEntries = _entryLimitController.text;

    Map<String, dynamic> requestBody = {};

    // Check if the input is a period ("."), or if it's empty or invalid
    if (maxEntries == ".") {
      print('Using all data');
      requestBody['max_entries'] = null; // Set to null to use all data
      requestBody['use_all_data'] = true; // Use all data if input is "."
    } else {
      // Try to parse maxEntries as an integer
      int? parsedMaxEntries = int.tryParse(maxEntries);

      if (parsedMaxEntries == null) {
        // If it's not a valid number, show an error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Invalid number, please enter a valid number or "."')),
        );
        return;
      }

      // If it's a valid number, proceed with using the parsed value
      requestBody['max_entries'] = parsedMaxEntries;
    }

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Model training started')),
        );
      } else {
        final errorData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${errorData['error']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect to server')),
      );
    }
  }

  void _resetDatabase(BuildContext context) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/reset-database'),
        headers: {
          'Authorization':
              'Bearer ${await FlutterSecureStorage().read(key: "auth_token")}'
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Database reset successfully.')),
        );
      } else {
        final responseData = jsonDecode(response.body);
        _showErrorDialog(
            context, responseData['message'] ?? 'Database reset failed.');
      }
    } catch (e) {
      _showErrorDialog(context, 'An error occurred: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome, Admin!',
                style: TextStyle(fontSize: 24),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _evaluateMetrics(context),
                child: Text('Evaluate Keystroke Metrics'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _entryLimitController,
                decoration: InputDecoration(
                  labelText: 'Max Entries Per User',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _trainModel(context),
                child: Text('Train Model'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _showResetConfirmationDialog(context),
                child: Text('Reset Database'),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _userIdController,
                decoration: InputDecoration(
                  labelText: 'User ID or Username',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _getUserDataCount(context),
                child: Text('Get User Data Count'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
