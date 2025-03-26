import 'package:flutter/material.dart';

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
      'lastActive': '2 min ago',
      'description': 'Advanced calculus discussions'
    },
    {
      'name': 'Physics Study',
      'members': 8,
      'active': false,
      'subject': 'Physics',
      'lastActive': '1 hour ago',
      'description': 'Quantum mechanics topics'
    },
    {
      'name': 'CS Fundamentals',
      'members': 15,
      'active': true,
      'subject': 'Computer Science',
      'lastActive': 'Just now',
      'description': 'Algorithms and data structures'
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
            onPressed: () => showSearch(
              context: context,
              delegate: RoomSearchDelegate(rooms: _studyRooms),
            ),
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showCreateRoomDialog,
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
                  return _buildRoomCard(room);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: _showCreateRoomDialog,
      ),
    );
  }

  Widget _buildRoomCard(Map<String, dynamic> room) {
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
        onTap: () => _joinRoom(room),
      ),
    );
  }

  Color _getSubjectColor(String subject) {
    switch (subject) {
      case 'Math': return Colors.blue;
      case 'Physics': return Colors.red;
      case 'Computer Science': return Colors.green;
      default: return Colors.purple;
    }
  }

  void _joinRoom(Map<String, dynamic> room) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoomDetailScreen(room: room),
      ),
    );
  }

  void _showCreateRoomDialog() {
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
  final List<Map<String, dynamic>> rooms;

  RoomSearchDelegate({required this.rooms});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = rooms.where((room) =>
        room['name'].toLowerCase().contains(query.toLowerCase()) ||
        room['subject'].toLowerCase().contains(query.toLowerCase()));

    return _buildResults(context, results.toList());
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = query.isEmpty
        ? rooms
        : rooms.where((room) =>
            room['name'].toLowerCase().contains(query.toLowerCase()) ||
            room['subject'].toLowerCase().contains(query.toLowerCase()));

    return _buildResults(context, suggestions.toList());
  }

  Widget _buildResults(BuildContext context, List<Map<String, dynamic>> results) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0E0058), Color(0xFF370290)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          final room = results[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: _getSubjectColor(room['subject']),
              child: Text(room['subject'][0]),
            ),
            title: Text(room['name'], style: TextStyle(color: Colors.white)),
            subtitle: Text(
              '${room['members']} members • ${room['lastActive']}',
              style: TextStyle(color: Colors.white70),
            ),
            onTap: () {
              close(context, room);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RoomDetailScreen(room: room),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getSubjectColor(String subject) {
    switch (subject) {
      case 'Math': return Colors.blue;
      case 'Physics': return Colors.red;
      case 'Computer Science': return Colors.green;
      default: return Colors.purple;
    }
  }
}

class RoomDetailScreen extends StatelessWidget {
  final Map<String, dynamic> room;

  RoomDetailScreen({required this.room});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(room['name'])),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0E0058), Color(0xFF370290)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: _getSubjectColor(room['subject']),
                child: Text(
                  room['subject'][0],
                  style: TextStyle(fontSize: 36, color: Colors.white),
                ),
              ),
              SizedBox(height: 20),
              Text(
                room['name'],
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
              SizedBox(height: 10),
              Text(
                '${room['members']} members',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {},
                child: Text('Join Room'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSubjectColor(String subject) {
    switch (subject) {
      case 'Math': return Colors.blue;
      case 'Physics': return Colors.red;
      case 'Computer Science': return Colors.green;
      default: return Colors.purple;
    }
  }
}