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
  String? _userStatus;
  bool _isLoggedIn = false;
  bool passwordFlag = false;
  bool usernameFlag = false;
  final List<double> _keyPressTimesTemp = [];
  final List<double> _keyReleaseTimesTemp = [];
  final List<double> _UserkeyPressTimesTemp = [];
  final List<double> _UserkeyReleaseTimesTemp = [];
  // Keystroke metrics
  final List<double> _keyPressTimes = [];
  final List<double> _keyReleaseTimes = [];
  int _backspaceCount = 0;
  //keystroke metrics for username
  final List<double> _keyPressTimesUsername = [];
  final List<double> _keyReleaseTimesUsername = [];
  int _backspaceCountUsername = 0;
  //bool _isKeyPressed = false;

  @override
  void initState() {
    super.initState();

    _usernameFocusNode.addListener(() {
      if (_usernameFocusNode.hasFocus) {
        setState(() {
          if (_usernameInput == "") {
            controller.reset();
          } else {
            controller.updateValue(_usernameInput);
          }
          _isKeyboardVisible =
              _usernameFocusNode.hasFocus; //set the keyboard visibility
        });
      } else {}
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

  void _registerUserKeystroke(double pressTime, double releaseTime) {
    if (pressTime != 0) {
      _UserkeyPressTimesTemp.add(pressTime);
    }
    if (releaseTime != 0) {
      _UserkeyReleaseTimesTemp.add(releaseTime);
    }
  }

  // Function to register keystrokes for password field
  void _registerKeystroke(double pressTime, double releaseTime) {
    if (pressTime != 0) {
      _keyPressTimesTemp.add(pressTime);
      print(('Key Pressed at: $pressTime')); // Debugging line
    }
    if (releaseTime != 0) {
      _keyReleaseTimesTemp.add(releaseTime);
    }
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
      print(_keyPressTimesTemp);
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
          'key_press_times_username': _keyPressTimesUsername.join(','),
          'key_release_times_username': _keyReleaseTimesUsername.join(','),
          'backspace_count_username': _backspaceCountUsername,
          'user_status': _userStatus,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['authenticated']) {
          await storage.write(key: 'auth_token', value: responseData['token']);

          var predictions = responseData['predictions'];
          String role =
              responseData['role']; // Fetch the user role from the response

          await storage.write(key: 'isLoggedIn', value: 'true');
          await storage.write(key: 'userName', value: _usernameController.text);
          await storage.write(
              key: 'predictions', value: jsonEncode(predictions));

          await storage.write(key: 'role', value: role);

          // Navigate based on role
          if (role == 'admin') {
            Navigator.pushReplacementNamed(context, '/admin', arguments: {
              'userName': _usernameController.text,
              'predictions': List<String>.from(predictions),
            });
          } else {
            Navigator.pushReplacementNamed(context, '/mainpage', arguments: {
              'userName': _usernameController.text,
              'predictions': List<String>.from(predictions),
            });
          }

          setState(() {
            _isLoggedIn = true;
          });
        }
      } else if (response.statusCode == 401) {
        _showErrorDialog(
            context, 'Authentication failed. Please check your credentials.');
        _resetController();
        _resetMetrics();
      } else {
        _showErrorDialog(context,
            'An error occurred: ${response.statusCode} ${response.reasonPhrase}');
        _resetController();
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

  void _resetController() {
    _passwordController.clear();
    _usernameController.clear();
    controller.reset();
  }

  void _resetMetrics() {
    _usernameInput = '';
    _passwordInput = '';
    _keyPressTimesTemp.clear();
    _keyReleaseTimesTemp.clear();
    _keyPressTimes.clear();
    _keyReleaseTimes.clear();
    _keyPressTimesUsername.clear();
    _keyReleaseTimesUsername.clear();
    _backspaceCountUsername = 0;
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
    _keyPressTimesUsername.add(_UserkeyPressTimesTemp.last);
    _keyReleaseTimesUsername.add(_UserkeyReleaseTimesTemp.last);

    if (_usernameInput.length > text.length) {
      _backspaceCountUsername++;
    }
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
    _keyPressTimes.add(_keyPressTimesTemp.last);
    _keyReleaseTimes.add(_keyReleaseTimesTemp.last);

    if (_passwordInput.length > text.length) {
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
          const SizedBox(height: 80),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _isLoggedIn ? Container() : _buildLoginForm(context),
              ),
            ),
          ),
          Listener(
            onPointerUp: (details) {
              if (_usernameFocusNode.hasFocus) {
                setState(() {
                  // Take the timestamp of the event and add it to the keyrelease times list
                  _registerUserKeystroke(
                      0, DateTime.now().millisecondsSinceEpoch.toDouble());
                });
              } else if (_passwordFocusNode.hasFocus) {
                setState(() {
                  // Take the timestamp of the event and add it to the keyrelease times list
                  _registerKeystroke(
                      0, DateTime.now().millisecondsSinceEpoch.toDouble());
                });
              }
            },
            onPointerDown: (details) {
              if (_usernameFocusNode.hasFocus) {
                setState(() {
                  _registerUserKeystroke(
                      DateTime.now().millisecondsSinceEpoch.toDouble(), 0);
                });
              } else if (_passwordFocusNode.hasFocus) {
                setState(() {
                  _registerKeystroke(
                      DateTime.now().millisecondsSinceEpoch.toDouble(), 0);
                });
              }
            },
            child: Visibility(
              visible: _isKeyboardVisible,
              maintainState: true, // Control visibility instead of removing
              child: Container(
                alignment: Alignment.bottomCenter,
                height: MediaQuery.of(context).size.height * 0.35,
                width: MediaQuery.of(context).size.width, // Full width
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
          // New DropdownButtonFormField to select user status
          DropdownButtonFormField<String>(
            value: _userStatus,
            decoration: const InputDecoration(
                labelText:
                    'User Status(This option is used for evaluating the models)'),
            items: <String>['Valid User', 'Intruder'].map((String status) {
              return DropdownMenuItem<String>(
                value: status,
                child: Text(status),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _userStatus = newValue;
              });
            },
            validator: (value) =>
                value == null ? 'Please select your status' : null,
          ),
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
