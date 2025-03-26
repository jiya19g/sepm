import 'package:flutter/material.dart';
import 'package:studybuddy_app/main_wrapper.dart';
import 'package:studybuddy_app/screens/home.dart';
import 'package:studybuddy_app/screens/rooms_screen.dart';
import 'package:studybuddy_app/screens/resources_screen.dart';
import 'package:studybuddy_app/screens/career_screen.dart';

void main() {
  runApp(StudyBuddyApp());
}

class StudyBuddyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudyBuddy',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: MainWrapper(), // This will handle all navigation
      debugShowCheckedModeBanner: false,
    );
  }
}