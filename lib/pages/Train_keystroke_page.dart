import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import 'package:custom_keyboard/custom_keyboard.dart';

class TrainKeystrokePage extends StatefulWidget {
  final String userName;

  const TrainKeystrokePage({super.key, required this.userName});

  @override
  _TrainKeystrokePageState createState() => _TrainKeystrokePageState();
}

class _TrainKeystrokePageState extends State<TrainKeystrokePage> {
  final GlobalKey _keyboardKey = GlobalKey();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final List<double> _keystrokeIntervals = [];
  //focus nodes
  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  String _serverMessage = '';
  //keystroke metrics for password
  int _backspaceCount = 0;
  final List<double> _keyPressTimes = [];
  final List<double> _keyReleaseTimes = [];
  //keystroke metrics for username
  final List<double> _keyPressTimesUsername = [];
  final List<double> _keyReleaseTimesUsername = [];
  final List<double> _keyPressTimesTemp = [];
  final List<double> _keyReleaseTimesTemp = [];
  final List<double> _UserkeyPressTimesTemp = [];
  final List<double> _UserkeyReleaseTimesTemp = [];
  int _backspaceCountUsername = 0;
  bool usernameFlag = false;
  bool passwordFlag = false;
  final CKController controller = CKController();
  String _passwordInput = '';
  String _usernameInput = '';
  bool _isKeyboardVisible = false;

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
    //print keypresstimes

    if (pressTime != 0) {
      _keyPressTimesTemp.add(pressTime);
    }
    if (releaseTime != 0) {
      _keyReleaseTimesTemp.add(releaseTime);
    }
  }

  // This function checks if the tap event is within the keyboard area
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

// Function to handle key press events ON MECHANICAL KEYBOARD
//KEEPING IT FOR REFERENCE
/*
  void _handleKeyPress(KeyEvent event) {
    if (_passwordFocusNode.hasFocus) {
      double now = DateTime.now().millisecondsSinceEpoch.toDouble();

      if (event is KeyDownEvent) {
        if (!_isKeyPressed) {
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
  }*/

  void _calculateKeystrokeInterval() {
    if (_keyPressTimes.length > 1) {
      for (int i = 1; i < _keyPressTimes.length; i++) {
        _keystrokeIntervals.add(_keyPressTimes[i] - _keyPressTimes[i - 1]);
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordFocusNode.dispose(); // Dispose the focus node
    controller.dispose();
    super.dispose();
  }

  // Calculate the error rate based on backspace count
  double _calculateErrorRate() {
    int totalKeystrokes = _keyPressTimes.length +
        _backspaceCount; // Total keypresses and backspaces
    if (totalKeystrokes == 0) return 0.0; // Avoid division by zero
    return (_backspaceCount / totalKeystrokes) *
        100; // Error rate in percentage
  }

  // Function to reset the keystroke data
  void _resetKeystrokeData() {
    _backspaceCount = 0;
    _keyPressTimes.clear();
    _keyReleaseTimes.clear();
    _keyPressTimesUsername.clear();
    _keyReleaseTimesUsername.clear();
    _backspaceCountUsername = 0;

    _keystrokeIntervals.clear();
    _passwordController.clear(); // Clear the password field
    _usernameController.clear();
    _passwordInput = '';
    _usernameInput = '';
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

  // Function to submit the keystroke data and the raw password
  void _submitKeystrokeData() async {
    final rawPassword = _passwordController.text;
    final rawusername = _usernameController.text;
    // Calculate intervals and error rate before submitting
    _calculateKeystrokeInterval();
    double errorRate = _calculateErrorRate();

    // Prepare data to send to the server
    final data = {
      'userName': rawusername,
      'password': rawPassword,
      'key_press_times': _keyPressTimes,
      'key_release_times': _keyReleaseTimes,
      'backspace_count': _backspaceCount,
      'keystroke_intervals': _keystrokeIntervals,
      'error_rate': errorRate,
      'key_press_times_username': _keyPressTimesUsername,
      'key_release_times_username': _keyReleaseTimesUsername,
      'backspace_count_username': _backspaceCountUsername,
    };

    // Code to submit data to the server using an HTTP POST request
    var url = Uri.parse('$baseUrl/train-keystroke');
    var response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    // Handle the server response
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      setState(() {
        _serverMessage = responseBody['message'];
      });
    } else {
      final responseBody = jsonDecode(response.body);
      setState(() {
        _serverMessage = responseBody['error'];
      });
    }

    // Show the server response to the user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_serverMessage)),
    );
    controller.reset();

    // Reset keystroke data after submission
    _resetKeystrokeData();
    //reload page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => TrainKeystrokePage(userName: widget.userName)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Train Keystroke Dynamics'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('User: ${widget.userName}',
                style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center, // Center the content vertically
                  children: [
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
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null; // Return null for valid input
                      },
                    ),
                    const SizedBox(
                        height: 20), // Space between text field and button
                    ElevatedButton(
                      onPressed: _submitKeystrokeData,
                      child: const Text('Submit Data'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Listener(
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
      ), // Hide the keyboard if not visible
    );
  }
}
