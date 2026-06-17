import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF99B4A0),
      body: Center(
        child: Text(
          'Profil',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
    );
  }
}