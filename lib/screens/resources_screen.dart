import 'package:flutter/material.dart';
import 'package:studybuddy_app/components/navbar.dart';
import 'package:studybuddy_app/screens/career_screen.dart';
import 'package:studybuddy_app/screens/home.dart';
import 'package:studybuddy_app/screens/rooms_screen.dart';

class ResourcesScreen extends StatefulWidget {
  @override
  _ResourcesScreenState createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  final List<Map<String, dynamic>> _resources = [
    {'title': 'Algebra Basics', 'type': 'PDF', 'uploadedBy': 'Alice'},
    {'title': 'Physics Lecture 1', 'type': 'Video', 'uploadedBy': 'Bob'},
    {'title': 'CS Algorithms', 'type': 'PDF', 'uploadedBy': 'Charlie'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Resources'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate: ResourceSearchDelegate());
            },
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showUploadDialog(context),
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
        child: ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: _resources.length,
          itemBuilder: (context, index) {
            final resource = _resources[index];
            return Card(
              color: Colors.white.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                leading: Icon(
                  resource['type'] == 'PDF' ? Icons.picture_as_pdf : Icons.video_library,
                  color: Colors.white,
                ),
                title: Text(
                  resource['title'],
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Uploaded by ${resource['uploadedBy']}',
                  style: TextStyle(color: Colors.white70),
                ),
                onTap: () => _openResource(context, resource),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _showUploadDialog(context),
      ),
      bottomNavigationBar: MainBottomNavBar(
        currentIndex: 2,
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

  void _openResource(BuildContext context, Map<String, dynamic> resource) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResourceDetailScreen(resource: resource),
      ),
    );
  }

  void _showUploadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Upload Resource'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Resource Title'),
            ),
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              items: ['PDF', 'Video']
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ))
                  .toList(),
              onChanged: (value) {},
              decoration: InputDecoration(labelText: 'Type'),
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
              // Upload logic here
              Navigator.pop(context);
            },
            child: Text('Upload'),
          ),
        ],
      ),
    );
  }
}

class ResourceSearchDelegate extends SearchDelegate {
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

class ResourceDetailScreen extends StatelessWidget {
  final Map<String, dynamic> resource;

  ResourceDetailScreen({required this.resource});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(resource['title']),
      ),
      body: Center(
        child: Text('Resource Details: ${resource['title']}'),
      ),
    );
  }
}
