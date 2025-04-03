import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:studybuddy_app/screens/resource_detail_screen.dart';

class ResourcesScreen extends StatefulWidget {
  @override
  _ResourcesScreenState createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  final _supabase = Supabase.instance.client;
  final _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _resources = [];
  bool _isLoading = true;
  String _searchQuery = '';
  Set<String> _selectedTags = {};

  @override
  void initState() {
    super.initState();
    _fetchResources();
  }

Future<void> _fetchResources() async {
  setState(() => _isLoading = true);
  
  try {
    String queryString = '*';
    if (_searchQuery.isNotEmpty || _selectedTags.isNotEmpty) {
      queryString = '''
        *,
        ${_searchQuery.isNotEmpty ? 'title.ilike.%${_searchQuery}%' : ''}
        ${_selectedTags.isNotEmpty ? 'tags.cs.{${_selectedTags.map((t) => '"$t"').join(',')}}' : ''}
      ''';
    }

    final response = await _supabase
        .from('resources')
        .select(queryString)
        .order('created_at', ascending: false);
    
    setState(() {
      _resources = List<Map<String, dynamic>>.from(response);
      _isLoading = false;
    });
  } catch (e) {
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error fetching resources: ${e.toString()}')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Resources', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black54),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
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
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                    _fetchResources();
                  },
                ),
                SizedBox(height: 12),
                _buildTagFilter(),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _resources.isEmpty
                    ? Center(child: Text('No resources found'))
                    : RefreshIndicator(
                        onRefresh: _fetchResources,
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue[800],
        child: Icon(Icons.add, color: Colors.white),
        onPressed: () => _showUploadDialog(context),
      ),
    );
  }

  Widget _buildTagFilter() {
    final allTags = _resources
        .expand((resource) => (resource['tags'] as List<dynamic>? ?? []))
        .whereType<String>()
        .toSet()
        .toList();

    return Wrap(
      spacing: 8,
      children: [
        FilterChip(
          label: Text('All'),
          selected: _selectedTags.isEmpty,
          onSelected: (_) {
            setState(() => _selectedTags.clear());
            _fetchResources();
          },
        ),
        ...allTags.map((tag) => FilterChip(
          label: Text(tag),
          selected: _selectedTags.contains(tag),
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedTags.add(tag);
              } else {
                _selectedTags.remove(tag);
              }
            });
            _fetchResources();
          },
        )),
      ],
    );
  }

  Widget _buildResourceCard(Map<String, dynamic> resource) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResourceDetailScreen(
              resource: resource,
              onDelete: _fetchResources,
            ),
          ),
        ),
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
                      : resource['type'] == 'Video'
                        ? Icons.video_library
                        : Icons.link,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${resource['user_id']} • ${_formatDate(resource['created_at'])}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    if ((resource['tags'] as List<dynamic>?)?.isNotEmpty ?? false)
                      SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        children: (resource['tags'] as List<dynamic>)
                            .whereType<String>()
                            .map<Widget>((tag) => Chip(
                              label: Text(tag, style: TextStyle(fontSize: 10)),
                              padding: EdgeInsets.all(0),
                              visualDensity: VisualDensity.compact,
                            )).toList(),
                      ),
                  ],
                ),
              ),
              Text(
                resource['size'] ?? '',
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
    switch (type) {
      case 'PDF':
        return Colors.red[600]!;
      case 'Video':
        return Colors.blue[600]!;
      default:
        return Colors.green[600]!;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 30) {
        return '${difference.inDays ~/ 30}mo ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _showUploadDialog(BuildContext context) async {
    String title = '';
    String type = 'PDF';
    List<String> tags = [];
    Uint8List? fileBytes;
    String? fileName;
    String? url;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
            child: SingleChildScrollView(
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
                    onChanged: (value) => title = value,
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: type,
                    items: ['PDF', 'Video', 'Link']
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => type = value!),
                    decoration: InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  if (type != 'Link')
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                      ),
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: type == 'PDF' 
                            ? FileType.custom 
                            : FileType.video,
                          allowedExtensions: type == 'PDF' ? ['pdf'] : null,
                        );
                        
                        if (result != null && result.files.isNotEmpty) {
                          setState(() {
                            fileBytes = result.files.first.bytes;
                            fileName = result.files.first.name;
                            if (title.isEmpty) {
                              title = result.files.first.name;
                            }
                          });
                        }
                      },
                      child: Text(
                        fileName != null 
                          ? 'Selected: ${fileName!.substring(0, fileName!.length < 15 ? fileName!.length : 15)}...'
                          : 'Select File',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                  if (type == 'Link')
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'URL',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) => url = value,
                    ),
                  SizedBox(height: 16),
                  Text('Tags:', style: TextStyle(fontWeight: FontWeight.w500)),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      InputChip(
                        label: Text('Math'),
                        selected: tags.contains('Math'),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              tags.add('Math');
                            } else {
                              tags.remove('Math');
                            }
                          });
                        },
                      ),
                      InputChip(
                        label: Text('Science'),
                        selected: tags.contains('Science'),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              tags.add('Science');
                            } else {
                              tags.remove('Science');
                            }
                          });
                        },
                      ),
                      InputChip(
                        label: Text('History'),
                        selected: tags.contains('History'),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              tags.add('History');
                            } else {
                              tags.remove('History');
                            }
                          });
                        },
                      ),
                    ],
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
                          backgroundColor: Colors.blue[800],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          if (title.isEmpty || (type != 'Link' && fileBytes == null)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Please fill all fields')),
                            );
                            return;
                          }
                          
                          Navigator.pop(context);
                          await _uploadResource(
                            title: title,
                            type: type,
                            tags: tags,
                            fileBytes: fileBytes,
                            fileName: fileName,
                            url: type == 'Link' ? url : null,
                          );
                        },
                        child: Text('UPLOAD'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _uploadResource({
    required String title,
    required String type,
    required List<String> tags,
    Uint8List? fileBytes,
    String? fileName,
    String? url,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Uploading...'),
          ],
        ),
      ),
    );

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');
      
      String? filePath;
      String? fileUrl;
      String size = '0 MB';
      
      if (type != 'Link' && fileBytes != null && fileName != null) {
        filePath = 'resources/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_$fileName';
        await _supabase.storage
            .from('resources')
            .uploadBinary(filePath, fileBytes);
        
        fileUrl = _supabase.storage
            .from('resources')
            .getPublicUrl(filePath);
        
        size = '${(fileBytes.length / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
      
      await _supabase.from('resources').insert({
        'title': title,
        'type': type,
        'user_id': user.uid,
        'file_path': filePath,
        'url': type == 'Link' ? url : fileUrl,
        'size': size,
        'tags': tags,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      Navigator.pop(context); // Close loading dialog
      await _fetchResources();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Resource uploaded successfully!')),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading resource: $e')),
      );
    }
  }
}