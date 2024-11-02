import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants.dart';
import 'package:custom_keyboard/custom_keyboard.dart';

class LoginHomePage extends StatefulWidget {
  const LoginHomePage({super.key});

  @override
  _LoginHomePageState createState() => _LoginHomePageState();
}

class _LoginHomePageState extends State<LoginHomePage> {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final CKController controller = CKController();
  final FocusNode _passwordFocusNode = FocusNode();
  final GlobalKey _keyboardKey = GlobalKey();
  final FocusNode _usernameFocusNode = FocusNode();
  bool _isKeyboardVisible = false;
  String _usernameInput = '';
  String _passwordInput = '';

  bool _isLoggedIn = false;
  bool passwordFlag = false;
  bool usernameFlag = false;

  // Keystroke metrics
  final List<double> _keyPressTimes = [];
  final List<double> _keyReleaseTimes = [];
  int _backspaceCount = 0;
  //bool _isKeyPressed = false;

  @override
  void initState() {
    super.initState();

    _usernameFocusNode.addListener(() {
      setState(() {
        if (_usernameInput == "") {
          controller.reset();
        } else {
          controller.updateValue(_usernameInput);
        }
        _isKeyboardVisible =
            _usernameFocusNode.hasFocus; //set the keyboard visibility
      });
    });

    _passwordFocusNode.addListener(() {
      setState(() {
        if (_passwordInput == "") {
          controller.reset();
        } else {
          controller.updateValue(_passwordInput);
        }
        _isKeyboardVisible =
            _passwordFocusNode.hasFocus; //set the keyboard visibility
      });
    });
  }

  // Function to register keystrokes
  void _registerKeystroke(double pressTime, double releaseTime) {
    //print keypresstimes
    print(_keyPressTimes);
    if (pressTime != 0) {
      _keyPressTimes.add(pressTime);
      print('Key Press Time Added: $pressTime'); // Debugging line
    }
    if (releaseTime != 0) {
      _keyReleaseTimes.add(releaseTime);
      print('Key Release Time Added: $releaseTime'); // Debugging line
    }

    print(
        'Key Press Times: ${_keyPressTimes.length}, Key Release Times: ${_keyReleaseTimes.length}');
  }
  //This function is used to capture keystrokes but not from software keyboard
  //i keep it here for future reference
  // Function to handle key press and release events
  /*
  void _handleKeyPress(KeyEvent event) {
    if (_passwordFocusNode.hasFocus) {
      double now = DateTime.now().millisecondsSinceEpoch.toDouble();

      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.tab) {
        } else if (!_isKeyPressed) {
          _registerKeystroke(now, 0); // Capture press time
          print('Key Pressed at: $now'); // Debugging line
          _isKeyPressed = true; // Update key pressed state
        }
      } else if (event is KeyUpEvent) {
        if (_isKeyPressed) {
          _registerKeystroke(0, now); // Capture release time
          print('Key Released at: $now'); // Debugging line
          _isKeyPressed = false; // Update key released state
        }
      }

      // Count backspace key press
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        _backspaceCount++; // Increment backspace count
      }
    }
  }
  */

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final response = await http.post(
        Uri.parse('$baseUrl/authenticate'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'username': _usernameController.text,
          'password': _passwordController.text,
          'key_press_times': _keyPressTimes.join(','),
          'key_release_times': _keyReleaseTimes.join(','),
          'backspace_count': _backspaceCount,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['authenticated']) {
          await storage.write(key: 'auth_token', value: responseData['token']);

          // Handle predictions
          var predictions = responseData['predictions'];
          await storage.write(key: 'isLoggedIn', value: 'true');
          await storage.write(key: 'userName', value: _usernameController.text);
          await storage.write(
              key: 'predictions', value: jsonEncode(predictions));
          print('Predictions: $predictions');

          // Navigate to the main page
          Navigator.pushReplacementNamed(context, '/mainpage', arguments: {
            'userName': _usernameController.text,
            'predictions': List<String>.from(predictions),
          });

          setState(() {
            _isLoggedIn = true;
          });
        }
      } else if (response.statusCode == 401) {
        _showErrorDialog(
            context, 'Authentication failed. Please check your credentials.');
        _passwordController.clear();
        controller.reset();
        _resetMetrics();
      } else {
        _showErrorDialog(context,
            'An error occurred: ${response.statusCode} ${response.reasonPhrase}');
        _passwordController.clear();
        controller.reset();
        _resetMetrics();
      }
    }
  }

  // This function checks if the tap event is within the keyboard area
  bool _isKeyboardArea(PointerDownEvent event) {
    // Get the keyboard widget's RenderBox and position
    final RenderBox? keyboardBox =
        _keyboardKey.currentContext?.findRenderObject() as RenderBox?;
    if (keyboardBox != null) {
      // Get the keyboard's size and position
      final Offset keyboardPosition = keyboardBox.localToGlobal(Offset.zero);
      final Size keyboardSize = keyboardBox.size;

      // Check if the event's position is within the keyboard's bounds
      return event.localPosition.dx >= keyboardPosition.dx &&
          event.localPosition.dx <= keyboardPosition.dx + keyboardSize.width &&
          event.localPosition.dy >= keyboardPosition.dy &&
          event.localPosition.dy <= keyboardPosition.dy + keyboardSize.height;
    }
    return false;
  }

  void _logout() {
    setState(() {
      _isLoggedIn = false;
      _usernameController.clear();
      _passwordController.clear();
      _resetMetrics();
    });
  }

  void _resetMetrics() {
    _keyPressTimes.clear();
    _keyReleaseTimes.clear();
    _backspaceCount = 0;
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

  void _handleUserChange(String text) {
    print("Handle User Change");
    setState(() {
      _usernameInput = text;
      _usernameController.value = TextEditingValue(
        text: _usernameInput,
        selection: TextSelection.fromPosition(
          TextPosition(offset: _usernameInput.length),
        ),
      );
    });
  }

  void _handlePasswordChange(String text) {
    print("Handle Password Change");
    if (_passwordInput.length > text.length) {
      print("Backspace Pressed");
      _backspaceCount++;
    }
    setState(() {
      _passwordInput = text;
      _passwordController.value = TextEditingValue(
        text: _passwordInput,
        selection: TextSelection.fromPosition(
          TextPosition(offset: _passwordInput.length),
        ),
      );
    });
  }

  @override
  void dispose() {
    controller.dispose();
    _passwordFocusNode.dispose(); // Dispose the focus node
    _usernameFocusNode.dispose(); // Dispose the focus node
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(_isLoggedIn ? 'Home' : 'Login'),
        automaticallyImplyLeading: false,
        actions: _isLoggedIn
            ? [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: _logout,
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _isLoggedIn ? Container() : _buildLoginForm(context),
              ),
            ),
          ),
          if (_isKeyboardVisible)
            Listener(
              onPointerUp: (details) {
                if (_passwordFocusNode.hasFocus) {
                  setState(() {
                    // Take the timestamp of the event and add it to the keyrelease times list
                    _registerKeystroke(
                        0, DateTime.now().millisecondsSinceEpoch.toDouble());
                    print("Tapped cancel on password field keyboard");
                  });
                }
              },
              onPointerDown: (details) {
                if (_passwordFocusNode.hasFocus) {
                  setState(() {
                    _registerKeystroke(
                        DateTime.now().millisecondsSinceEpoch.toDouble(), 0);
                    print("Tapped down on password field keyboard");
                    print(details.localPosition);
                    print(details.kind);
                  });
                }
              },
              child: Container(
                alignment: Alignment.bottomCenter,
                height: MediaQuery.of(context).size.height * 0.35,
                child: CustomKeyboard(
                  key: _keyboardKey,
                  backgroundColor: Colors.white,
                  bottomPaddingColor: Colors.transparent,
                  bottomPaddingHeight: 0,
                  keyboardHeight: MediaQuery.of(context).size.height * 0.35,
                  keyboardWidth: MediaQuery.of(context).size.width,
                  onTapColor: Colors.blue,
                  textColor: Colors.black,
                  keybordButtonColor: Colors.white,
                  elevation: WidgetStateProperty.all(5.0),
                  controller: controller,
                  onChange: (text) => {
                    if (usernameFlag)
                      {_handleUserChange(text)}
                    else if (passwordFlag)
                      {_handlePasswordChange(text)}
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Image.asset(
            'assets/logo.jpg',
            width: 100, // Adjust the width as needed
            height: 100, // Adjust the height as needed
          ),
          TextFormField(
            onTapOutside: (event) {
              if (!_isKeyboardArea(event)) {
                setState(() {
                  _usernameFocusNode.unfocus();
                  _isKeyboardVisible = false;
                });
              }
            },
            keyboardType: TextInputType.none,
            focusNode: _usernameFocusNode,
            controller: _usernameController,
            decoration: const InputDecoration(labelText: 'Username'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your username';
              }
              return null; // Return null for valid input
            },
            onTap: () {
              print('Username field tapped'); // Debugging line
              _usernameFocusNode.requestFocus(); // Request focus on tap
              usernameFlag = true;
              passwordFlag = false;
            },
          ),
          TextFormField(
            onTapOutside: (event) {
              if (!_isKeyboardArea(event)) {
                setState(() {
                  _passwordFocusNode.unfocus();
                  _isKeyboardVisible = false;
                });
              }
            },
            onTap: () {
              print('Password field tapped'); // Debugging line
              _passwordFocusNode.requestFocus(); // Request focus on tap
              passwordFlag = true;
              usernameFlag = false;
            },
            keyboardType: TextInputType.none,
            focusNode: _passwordFocusNode, // Focus node for password field
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              return null; // Return null for valid input
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _login,
            child: const Text('Login'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/signup');
            },
            child: const Text('Don\'t have an account? Sign up'),
          ),
        ],
      ),
    );
  }
}
