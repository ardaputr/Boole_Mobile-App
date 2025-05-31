import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_preview/device_preview.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(
    DevicePreview(
      enabled: true, // Set false kalau mau matikan preview
      builder: (context) => const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _email;
  String? _fullName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email');
    final fullName = prefs.getString('full_name');

    setState(() {
      _email = email;
      _fullName = fullName;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      useInheritedMediaQuery:
          true, // penting untuk Device Preview agar responsive
      locale: DevicePreview.locale(context), // agar locale ikut preview
      builder: DevicePreview.appBuilder, // wrap app dengan Device Preview
      title: 'Boole',
      theme: ThemeData(primarySwatch: Colors.teal),
      home:
          (_email != null && _fullName != null)
              ? HomeScreen(userName: _fullName!, email: _email!)
              : const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
