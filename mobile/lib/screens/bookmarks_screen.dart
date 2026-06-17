import 'package:flutter/material.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF99B4A0),
      body: Center(
        child: Text(
          'Favoris',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
    );
  }
}