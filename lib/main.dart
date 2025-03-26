import 'package:flutter/material.dart';
import 'package:studybuddy_app/screens/home.dart';
import 'package:studybuddy_app/screens/rooms_screen.dart';
import 'package:studybuddy_app/screens/resources_screen.dart';
import 'package:studybuddy_app/screens/career_screen.dart';
import 'package:studybuddy_app/components/navbar.dart';

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
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AppWrapper(),
      routes: {
        '/home': (context) => HomeScreen(),
        '/rooms': (context) => RoomsScreen(),
        '/resources': (context) => ResourcesScreen(),
        '/career': (context) => CareerScreen(),
      },
    );
  }
}

class AppWrapper extends StatefulWidget {
  @override
  _AppWrapperState createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    RoomsScreen(),
    ResourcesScreen(),
    CareerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: MainBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          // Update the URL route if needed
          Navigator.pushReplacementNamed(
            context,
            MainBottomNavBar.routes[index]!,
          );
        },
      ),
    );
  }
}