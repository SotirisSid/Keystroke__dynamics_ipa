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
  final TextEditingController _passwordController = TextEditingController();
  int _backspaceCount = 0;
  final List<double> _keyPressTimes = [];
  final List<double> _keyReleaseTimes = [];
  final List<double> _keystrokeIntervals = [];
  final FocusNode _passwordFocusNode = FocusNode();
  String _serverMessage = '';

  final CKController controller = CKController();
  String _passwordInput = '';
  bool _isKeyboardVisible = false;

  @override
  void initState() {
    super.initState();
    _passwordFocusNode.addListener(() {
      setState(() {
        if (_passwordInput == "") {
          controller.reset();
        } else {
          print("Else branch");
          controller.updateValue(_passwordInput);
        }
        _isKeyboardVisible =
            _passwordFocusNode.hasFocus; //set the keyboard visibility
      });
    });
  }

  // Function to register keystrokes
  void _registerKeystroke(double pressTime, double releaseTime) {
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
    _keystrokeIntervals.clear();
    _passwordController.clear(); // Clear the password field
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

  // Function to submit the keystroke data and the raw password
  void _submitKeystrokeData() async {
    final rawPassword = _passwordController.text;

    // Calculate intervals and error rate before submitting
    _calculateKeystrokeInterval();
    double errorRate = _calculateErrorRate();

    // Prepare data to send to the server
    final data = {
      'userName': widget.userName,
      'password': rawPassword,
      'key_press_times': _keyPressTimes,
      'key_release_times': _keyReleaseTimes,
      'backspace_count': _backspaceCount,
      'keystroke_intervals': _keystrokeIntervals,
      'error_rate': errorRate,
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
                            _passwordFocusNode.unfocus();
                            _isKeyboardVisible = false;
                          });
                        }
                      },
                      onTap: () {
                        print('Password field tapped'); // Debugging line
                        _passwordFocusNode
                            .requestFocus(); // Request focus on tap
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
      // The custom keyboard should be placed outside the Padding to allow full width
      bottomNavigationBar: _isKeyboardVisible
          ? SizedBox(
              width:
                  MediaQuery.of(context).size.width, // Full width of the screen
              height: MediaQuery.of(context).size.height *
                  0.35, // Set the height of the keyboard
              child: Listener(
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
                child: CustomKeyboard(
                  backgroundColor: Colors.white,
                  bottomPaddingColor: Colors.transparent,
                  bottomPaddingHeight: 0,
                  keyboardHeight: MediaQuery.of(context).size.height * 0.35,
                  keyboardWidth:
                      MediaQuery.of(context).size.width, // Ensure full width
                  onTapColor: Colors.blue,
                  textColor: Colors.black,
                  keybordButtonColor: Colors.white,
                  elevation: MaterialStateProperty.all(5.0),
                  controller: controller,
                  onChange: (text) => {_handlePasswordChange(text)},
                ),
              ),
            )
          : null, // Hide the keyboard if not visible
    );
  }
}
