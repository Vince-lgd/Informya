import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const InformyaApp());
}

class InformyaApp extends StatelessWidget {
  const InformyaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Informya',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}