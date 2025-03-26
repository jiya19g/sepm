import 'package:flutter/material.dart';
import 'package:studybuddy_app/components/navbar.dart';
import 'package:studybuddy_app/screens/career_screen.dart';
import 'package:studybuddy_app/screens/home.dart';
import 'package:studybuddy_app/screens/resources_screen.dart';

class RoomsScreen extends StatefulWidget {
  @override
  _RoomsScreenState createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  final List<Map<String, dynamic>> _studyRooms = [
    {
      'name': 'Mathematics Group',
      'members': 12,
      'active': true,
      'subject': 'Math',
      'lastActive': '2 min ago'
    },
    {
      'name': 'Physics Study',
      'members': 8,
      'active': false,
      'subject': 'Physics',
      'lastActive': '1 hour ago'
    },
    {
      'name': 'CS Fundamentals',
      'members': 15,
      'active': true,
      'subject': 'Computer Science',
      'lastActive': 'Just now'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Study Rooms'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate: RoomSearchDelegate());
            },
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showCreateRoomDialog(context),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0E0058), Color(0xFF370290)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search rooms...',
                  prefixIcon: Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: _studyRooms.length,
                itemBuilder: (context, index) {
                  final room = _studyRooms[index];
                  return Card(
                    color: Colors.white.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getSubjectColor(room['subject']),
                        child: Text(room['subject'][0]),
                      ),
                      title: Text(
                        room['name'],
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${room['members']} members • ${room['lastActive']}',
                        style: TextStyle(color: Colors.white70),
                      ),
                      trailing: room['active']
                          ? Chip(
                              label: Text('Active'),
                              backgroundColor: Colors.green,
                            )
                          : null,
                      onTap: () => _joinRoom(context, room),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _showCreateRoomDialog(context),
      ),
      bottomNavigationBar: MainBottomNavBar(
        currentIndex: 1,
        onTap: (index) {
          setState(() {
            Navigator.popUntil(context, (route) => route.isFirst);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => _getScreen(index)),
            );
          });
        },
      ),
    );
  }

  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        return HomeScreen();
      case 1:
        return RoomsScreen();
      case 2:
        return ResourcesScreen();
      case 3:
        return CareerScreen();
      default:
        return HomeScreen();
    }
  }

  Color _getSubjectColor(String subject) {
    switch (subject) {
      case 'Math':
        return Colors.blue;
      case 'Physics':
        return Colors.red;
      case 'Computer Science':
        return Colors.green;
      default:
        return Colors.purple;
    }
  }

  void _joinRoom(BuildContext context, Map<String, dynamic> room) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoomDetailScreen(room: room),
      ),
    );
  }

  void _showCreateRoomDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create New Room'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Room Name'),
            ),
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              items: ['Math', 'Physics', 'Computer Science', 'Biology']
                  .map((subject) => DropdownMenuItem(
                        value: subject,
                        child: Text(subject),
                      ))
                  .toList(),
              onChanged: (value) {},
              decoration: InputDecoration(labelText: 'Subject'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Add room creation logic
              Navigator.pop(context);
            },
            child: Text('Create'),
          ),
        ],
      ),
    );
  }
}

class RoomSearchDelegate extends SearchDelegate {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Center(child: Text('Search results for: $query'));
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Center(child: Text('Search suggestions'));
  }
}

class RoomDetailScreen extends StatelessWidget {
  final Map<String, dynamic> room;

  RoomDetailScreen({required this.room});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(room['name']),
      ),
      body: Center(
        child: Text('Room Details: ${room['name']}'),
      ),
    );
  }
}
