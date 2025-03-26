import 'package:flutter/material.dart';

class MainBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  static const Map<int, String> routes = {
    0: '/home',
    1: '/rooms',
    2: '/resources',
    3: '/career',
  };

  MainBottomNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.deepPurple,
          unselectedItemColor: Colors.grey[600],
          backgroundColor: Colors.white,
          elevation: 10,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 12,
          ),
          items: [
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(5),
                child: Icon(Icons.home_outlined),
              ),
              activeIcon: Container(
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.home_filled),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(5),
                child: Icon(Icons.groups_outlined),
              ),
              activeIcon: Container(
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.groups),
              ),
              label: 'Rooms',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(5),
                child: Icon(Icons.folder_outlined),
              ),
              activeIcon: Container(
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.folder),
              ),
              label: 'Resources',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(5),
                child: Icon(Icons.work_outline),
              ),
              activeIcon: Container(
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.work),
              ),
              label: 'Career',
            ),
          ],
        ),
      ),
    );
  }
}