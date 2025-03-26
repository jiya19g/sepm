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
        title: Text('Study Rooms', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.black54),
            onPressed: () => showSearch(
              context: context,
              delegate: RoomSearchDelegate(rooms: _studyRooms),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search rooms...',
                prefixIcon: Icon(Icons.search, color: Colors.black54),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: _studyRooms.length,
              separatorBuilder: (context, index) => SizedBox(height: 8),
              itemBuilder: (context, index) {
                final room = _studyRooms[index];
                return _buildRoomCard(room);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueGrey[800],
        child: Icon(Icons.add, color: Colors.white),
        onPressed: _showCreateRoomDialog,
      ),
    );
  }

  Widget _buildRoomCard(Map<String, dynamic> room) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _joinRoom(room),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getSubjectColor(room['subject']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    room['subject'][0],
                    style: TextStyle(
                      color: _getSubjectColor(room['subject']),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room['name'],
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${room['members']} members • ${room['lastActive']}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (room['active'])
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Active',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSubjectColor(String subject) {
    switch (subject) {
      case 'Math': return Colors.blue[800]!;
      case 'Physics': return Colors.red[700]!;
      case 'Computer Science': return Colors.teal[600]!;
      default: return Colors.blueGrey[800]!;
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
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Create New Room',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Room Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                items: ['Math', 'Physics', 'Computer Science', 'Biology']
                    .map((subject) => DropdownMenuItem(
                          value: subject,
                          child: Text(subject),
                        ))
                    .toList(),
                onChanged: (value) {},
                decoration: InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('CANCEL'),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey[800],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      // Add room creation logic
                      Navigator.pop(context);
                    },
                    child: Text('CREATE'),
                  ),
                ],
              ),
            ],
          ),
        ),
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
        icon: Icon(Icons.clear, color: Colors.black54),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back, color: Colors.black54),
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
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final room = results[index];
        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getSubjectColor(room['subject']).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                room['subject'][0],
                style: TextStyle(
                  color: _getSubjectColor(room['subject']),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          title: Text(room['name']),
          subtitle: Text(
            '${room['members']} members • ${room['lastActive']}',
            style: TextStyle(color: Colors.grey[600]),
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
    );
  }

  Color _getSubjectColor(String subject) {
    switch (subject) {
      case 'Math': return Colors.blue[800]!;
      case 'Physics': return Colors.red[700]!;
      case 'Computer Science': return Colors.teal[600]!;
      default: return Colors.blueGrey[800]!;
    }
  }
}

class RoomDetailScreen extends StatelessWidget {
  final Map<String, dynamic> room;

  RoomDetailScreen({required this.room});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(room['name'], style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black54),
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _getSubjectColor(room['subject']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  room['subject'][0],
                  style: TextStyle(
                    color: _getSubjectColor(room['subject']),
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: 24),
            Text(
              room['name'],
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '${room['members']} members',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            SizedBox(height: 16),
            Text(
              room['description'],
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 15,
              ),
            ),
            Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey[800],
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {},
                child: Text('JOIN ROOM'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSubjectColor(String subject) {
    switch (subject) {
      case 'Math': return Colors.blue[800]!;
      case 'Physics': return Colors.red[700]!;
      case 'Computer Science': return Colors.teal[600]!;
      default: return Colors.blueGrey[800]!;
    }
  }
}