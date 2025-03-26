import 'package:flutter/material.dart';

class ResourcesScreen extends StatefulWidget {
  @override
  _ResourcesScreenState createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  final List<Map<String, dynamic>> _resources = [
    {
      'title': 'Algebra Basics', 
      'type': 'PDF', 
      'uploadedBy': 'Alice',
      'date': '2 days ago',
      'size': '2.4 MB'
    },
    {
      'title': 'Physics Lecture 1', 
      'type': 'Video', 
      'uploadedBy': 'Bob',
      'date': '1 week ago',
      'size': '156 MB'
    },
    {
      'title': 'CS Algorithms', 
      'type': 'PDF', 
      'uploadedBy': 'Charlie',
      'date': '3 hours ago',
      'size': '5.1 MB'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Resources', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black54),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.black54),
            onPressed: () => showSearch(
              context: context, 
              delegate: ResourceSearchDelegate(resources: _resources),
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
                hintText: 'Search resources...',
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
              itemCount: _resources.length,
              separatorBuilder: (context, index) => SizedBox(height: 8),
              itemBuilder: (context, index) {
                final resource = _resources[index];
                return _buildResourceCard(resource);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueGrey[800],
        child: Icon(Icons.add, color: Colors.white),
        onPressed: () => _showUploadDialog(context),
      ),
    );
  }

  Widget _buildResourceCard(Map<String, dynamic> resource) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openResource(context, resource),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getTypeColor(resource['type']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    resource['type'] == 'PDF' 
                      ? Icons.picture_as_pdf 
                      : Icons.video_library,
                    color: _getTypeColor(resource['type']),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resource['title'],
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${resource['uploadedBy']} • ${resource['date']}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                resource['size'],
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    return type == 'PDF' ? Colors.red[600]! : Colors.blue[600]!;
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
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Upload Resource',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Resource Title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                items: ['PDF', 'Video']
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) {},
                decoration: InputDecoration(
                  labelText: 'Type',
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
                      // Upload logic here
                      Navigator.pop(context);
                    },
                    child: Text('UPLOAD'),
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

class ResourceSearchDelegate extends SearchDelegate {
  final List<Map<String, dynamic>> resources;

  ResourceSearchDelegate({required this.resources});

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
    final results = resources.where((resource) =>
        resource['title'].toLowerCase().contains(query.toLowerCase()) ||
        resource['uploadedBy'].toLowerCase().contains(query.toLowerCase()));

    return _buildResults(context, results.toList());
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = query.isEmpty
        ? resources
        : resources.where((resource) =>
            resource['title'].toLowerCase().contains(query.toLowerCase()) ||
            resource['uploadedBy'].toLowerCase().contains(query.toLowerCase()));

    return _buildResults(context, suggestions.toList());
  }

  Widget _buildResults(BuildContext context, List<Map<String, dynamic>> results) {
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final resource = results[index];
        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getTypeColor(resource['type']).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                resource['type'] == 'PDF' 
                  ? Icons.picture_as_pdf 
                  : Icons.video_library,
                color: _getTypeColor(resource['type']),
                size: 20,
              ),
            ),
          ),
          title: Text(resource['title']),
          subtitle: Text(
            '${resource['uploadedBy']} • ${resource['date']}',
            style: TextStyle(color: Colors.grey[600]),
          ),
          trailing: Text(
            resource['size'],
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          onTap: () {
            close(context, resource);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ResourceDetailScreen(resource: resource),
              ),
            );
          },
        );
      },
    );
  }

  Color _getTypeColor(String type) {
    return type == 'PDF' ? Colors.red[600]! : Colors.blue[600]!;
  }
}

class ResourceDetailScreen extends StatelessWidget {
  final Map<String, dynamic> resource;

  ResourceDetailScreen({required this.resource});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(resource['title'], style: TextStyle(color: Colors.black87)),
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
                color: _getTypeColor(resource['type']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Icon(
                  resource['type'] == 'PDF' 
                    ? Icons.picture_as_pdf 
                    : Icons.video_library,
                  color: _getTypeColor(resource['type']),
                  size: 36,
                ),
              ),
            ),
            SizedBox(height: 24),
            Text(
              resource['title'],
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Uploaded by ${resource['uploadedBy']}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDetailItem(Icons.calendar_today, resource['date']),
                SizedBox(width: 24),
                _buildDetailItem(Icons.sd_storage, resource['size']),
              ],
            ),
            Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getTypeColor(resource['type']),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {},
                child: Text(
                  'OPEN ${resource['type']}',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        SizedBox(height: 4),
        Text(
          text,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
      ],
    );
  }

  Color _getTypeColor(String type) {
    return type == 'PDF' ? Colors.red[600]! : Colors.blue[600]!;
  }
}