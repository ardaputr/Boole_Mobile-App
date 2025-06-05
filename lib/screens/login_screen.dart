import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:another_flushbar/flushbar.dart'; // Import Flushbar

import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool showWelcomeNotification;

  const LoginScreen({super.key, this.showWelcomeNotification = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  bool _passwordVisible = false;

  @override
  void initState() {
    super.initState();

    if (widget.showWelcomeNotification) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showWelcomeNotification();
      });
    }
  }

  void _showWelcomeNotification() {
    Flushbar(
      message: "Let's go to explore",
      icon: const Icon(Icons.chat_bubble, size: 28.0, color: Colors.white),
      duration: const Duration(seconds: 3),
      flushbarPosition: FlushbarPosition.TOP,
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(10),
      backgroundColor: Colors.cyan,
      animationDuration: const Duration(milliseconds: 500),
      mainButton: TextButton(
        onPressed: () {
          Navigator.of(
            context,
          ).pop(); // Tutup notifikasi saat tombol OK ditekan
        },
        child: const Text('OK', style: TextStyle(color: Colors.white)),
      ),
    ).show(context);
  }

  Future<void> _saveSession(int id, String email, String fullName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', id);
    await prefs.setString('email', email);
    await prefs.setString('full_name', fullName);
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // final url = "https://boole-boolebe-525057870643.us-central1.run.app/login";
    final url = "http://192.168.100.199:5000/login";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": _emailController.text.trim(),
          "password": _passwordController.text,
        }),
      );

      final data = jsonDecode(response.body);
      print("Response: $data");

      if (data['success'] == true) {
        final user = data['user'];
        await _saveSession(user['id'], user['email'], user['full_name']);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) => HomeScreen(
                  userName: user['full_name'],
                  email: user['email'],
                ),
          ),
        );
      } else {
        setState(() {
          _error = data['message'] ?? 'Login failed';
        });
      }
    } catch (e) {
      setState(() {
        _error = "An error occurred: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: !_passwordVisible,
      decoration: InputDecoration(
        hintText: 'Enter Your Password',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        suffixIcon: IconButton(
          icon: Icon(
            _passwordVisible ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            setState(() {
              _passwordVisible = !_passwordVisible;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Hi, Welcome Back!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26),
            ),
            const SizedBox(height: 20),
            const Text('Email', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Enter Your Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Password',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            _buildPasswordField(),
            const SizedBox(height: 16),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  backgroundColor: Colors.cyan,
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                          'Login',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
              ),
            ),
            const SizedBox(height: 40),
            Row(
              children: const [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Or With'),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 40),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don’t have an account ? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        color: Colors.indigo,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
