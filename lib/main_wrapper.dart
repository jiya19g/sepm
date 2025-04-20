import 'package:flutter/material.dart';
import 'package:studybuddy_app/screens/home.dart';
import 'package:studybuddy_app/screens/rooms_screen.dart';
import 'package:studybuddy_app/screens/resources_screen.dart';
import 'package:studybuddy_app/screens/career_screen.dart';

class MainWrapper extends StatefulWidget {
  @override
  _MainWrapperState createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  // List of all screens
  final List<Widget> _screens = [
    HomeScreen(),
    StudyRoomScreen(),
    ResourcesScreen(),
    CareerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The current screen based on selected index
      body: _screens[_currentIndex],
      
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index; // Update the current index
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups),
            label: 'Rooms',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder),
            label: 'Resources',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'Career',
          ),
        ],
      ),
    );
  }
}