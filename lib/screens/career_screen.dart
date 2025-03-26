import 'package:flutter/material.dart';
import 'package:studybuddy_app/components/navbar.dart';

class CareerScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Career Corner')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0E0058), Color(0xFF370290)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(child: Text('Career Content', style: TextStyle(color: Colors.white))),
      ),
      bottomNavigationBar: MainBottomNavBar(currentIndex: 3, onTap: (index) {}),
    );
  }
}