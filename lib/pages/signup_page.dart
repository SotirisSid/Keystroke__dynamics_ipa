import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import "../constants.dart";
import 'package:custom_keyboard/custom_keyboard.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final GlobalKey _keyboardKey = GlobalKey();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final CKController controller = CKController();
  final List<double> _keyPressTimes = [];
  final List<double> _keyReleaseTimes = [];
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _usernameFocusNode = FocusNode();
  int _backspaceCount = 0; // Count the number of backspaces
  //keystroke metrics for username
  final List<double> _keyPressTimesUsername = [];
  final List<double> _keyReleaseTimesUsername = [];
  final List<double> _UserkeyPressTimesTemp = [];
  final List<double> _UserkeyReleaseTimesTemp = [];
  final List<double> _keyPressTimesTemp = [];
  final List<double> _keyReleaseTimesTemp = [];
  int _backspaceCountUsername = 0;
  bool _isKeyboardVisible = false;
  String _usernameInput = '';
  String _passwordInput = '';
  bool passwordFlag = false;
  bool usernameFlag = false;

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

  bool _isKeyboardArea(PointerDownEvent event) {
    final RenderBox? keyboardBox =
        _keyboardKey.currentContext?.findRenderObject() as RenderBox?;
    if (keyboardBox != null) {
      final Offset keyboardPosition = keyboardBox.localToGlobal(Offset.zero);
      final Size keyboardSize = keyboardBox.size;

      return event.position.dx >= keyboardPosition.dx &&
          event.position.dx <= keyboardPosition.dx + keyboardSize.width &&
          event.position.dy >= keyboardPosition.dy &&
          event.position.dy <= keyboardPosition.dy + keyboardSize.height;
    }
    return false;
  }

  void _registerUserKeystroke(double pressTime, double releaseTime) {
    if (pressTime != 0) {
      _UserkeyPressTimesTemp.add(pressTime);
    }
    if (releaseTime != 0) {
      _UserkeyReleaseTimesTemp.add(releaseTime);
    }
  }

  // Function to register keystrokes
  void _registerKeystroke(double pressTime, double releaseTime) {
    //print keypresstimes

    if (pressTime != 0) {
      _keyPressTimesTemp.add(pressTime);
    }
    if (releaseTime != 0) {
      _keyReleaseTimesTemp.add(releaseTime);
    }
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

  bool validateStructure(String value) {
    String pattern =
        r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$';
    RegExp regExp = RegExp(pattern);
    return regExp.hasMatch(value);
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
// Function to handle input changes on a mechanical keyboard doesnt work on soft keyboard
//keeping it for reference
  // Function to handle input changes
  /*
  void _onInputChange(String value) {
    double now = DateTime.now().millisecondsSinceEpoch.toDouble();

    // Register key press when user starts typing
    if (value.isNotEmpty && !_isTyping) {
      _registerKeystroke(now, 0); // Capture press time
      _isTyping = true; // Set typing state
    }

    // Register key release when the user finishes typing
    if (value.isEmpty && _isTyping) {
      _registerKeystroke(0, now); // Capture release time
      _isTyping = false; // Reset typing state
    }

    // Check for backspace
    if (_passwordController.text.length > value.length) {
      _backspaceCount++; // Increment backspace count
    }
  }
  */

  // Function to handle signup and send data to the server
  Future<void> _signup(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      // Send data to the server
      final response = await http.post(
        Uri.parse('$baseUrl/register_keystrokes'), // Use your actual base URL
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'username': _usernameController.text,
          'password': _passwordController.text,
          'key_press_times': _keyPressTimes.join(','), // Send key press times
          'key_release_times':
              _keyReleaseTimes.join(','), // Send key release times
          'backspace_count': _backspaceCount, // Send backspace count
          'key_press_times_username': _keyPressTimesUsername.join(','),
          'key_release_times_username': _keyReleaseTimesUsername.join(','),
          'backspace_count_username': _backspaceCountUsername,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context); // Navigate back on success
      } else {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text(responseData['error'] ?? 'Unknown error'),
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
        controller.reset();
        _passwordController.clear();
        _usernameController.clear();
        _usernameInput = '';
        _passwordInput = '';
        FocusScope.of(context).requestFocus(FocusNode());
      }

      // Reset data after sending
      _keyPressTimesUsername.clear();
      _keyReleaseTimesUsername.clear();
      _backspaceCountUsername = 0; // Reset backspace count
      _keyPressTimes.clear();
      _keyReleaseTimes.clear();
      _backspaceCount = 0; // Reset backspace count
    }
  }

  @override
  void dispose() {
    print("dispose called");
    _usernameFocusNode.removeListener(() {});
    _passwordFocusNode.removeListener(() {});
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
        title: const Text('Sign Up'),
      ),
      body: GestureDetector(
        onTap: () {
          // Unfocus the input fields and hide the keyboard
          // FocusScope.of(context).unfocus();
          //setState(() {
          // _isKeyboardVisible = false; // Hide the keyboard
          //});
        },
        child: Column(
          children: <Widget>[
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize
                          .min, // Allow the column to be as small as possible
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
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            errorMaxLines:
                                3, // Allow error messages to span up to 3 lines
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your username';
                            }

                            // Regex for validating username
                            final usernameRegex =
                                RegExp(r'^[a-zA-Z0-9._]{3,15}$');
                            if (!usernameRegex.hasMatch(value)) {
                              return 'Username must be 3-15 characters long and can only contain letters, numbers, dots, and underscores.';
                            }

                            return null; // Return null for valid input
                          },
                          onTap: () {
                            _usernameFocusNode
                                .requestFocus(); // Request focus on tap
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
                            _passwordFocusNode
                                .requestFocus(); // Request focus on tap
                            passwordFlag = true;
                            usernameFlag = false;
                          },
                          keyboardType: TextInputType.none,
                          focusNode:
                              _passwordFocusNode, // Focus node for password field
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            errorMaxLines:
                                3, // Allows error messages to have up to 2 lines
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (!validateStructure(value)) {
                              return 'Password must be at least 8 characters long, include an uppercase letter, a lowercase letter, a number, and a special character.';
                            }
                            return null; // Return null for valid input
                          },
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => _signup(context),
                          child: const Text('Sign Up'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Custom Keyboard at the bottom
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
                maintainState: true,
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
      ),
    );
  }
}
