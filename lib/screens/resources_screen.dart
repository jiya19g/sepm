import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'database_helper.dart';

class ResourcesScreen extends StatefulWidget {
  @override
  _ResourcesScreenState createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _resources = [];

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  Future<void> _loadResources() async {
    final resources = await _dbHelper.getResources();
    setState(() {
      _resources = resources;
    });
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
        onTap: () => _openResource(resource),
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
                      'Uploaded ${resource['uploadDate']}',
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

  Future<void> _openResource(Map<String, dynamic> resource) async {
    if (resource['filePath'] != null) {
      final file = File(resource['filePath']);
      if (await file.exists()) {
        await OpenFilex.open(file.path);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File not found')),
        );
      }
    }
  }

  void _showUploadDialog(BuildContext context) {
    final TextEditingController _titleController = TextEditingController();
    String _selectedType = 'PDF';
    PlatformFile? _pickedFile;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
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
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Resource Title',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  items: ['PDF', 'Video', 'Document']
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      FilePickerResult? result = await FilePicker.platform.pickFiles();
                      
                      if (result != null) {
                        setState(() {
                          _pickedFile = result.files.first;
                        });
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error picking file: $e')),
                      );
                    }
                  },
                  child: Text(_pickedFile == null ? 'SELECT FILE' : 'File Selected: ${_pickedFile!.name}'),
                ),
                if (_pickedFile != null) 
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Size: ${(_pickedFile!.size / 1024).toStringAsFixed(1)} KB',
                      style: TextStyle(color: Colors.grey),
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
                      onPressed: () async {
                        if (_titleController.text.isEmpty || _pickedFile == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Please provide all details')),
                          );
                          return;
                        }

                        // Get the application documents directory
                        final appDir = await getApplicationDocumentsDirectory();
                        // Create a resources directory if it doesn't exist
                        final resourcesDir = Directory('${appDir.path}/resources');
                        if (!await resourcesDir.exists()) {
                          await resourcesDir.create();
                        }

                        // Copy the file to the resources directory
                        final newPath = '${resourcesDir.path}/${_pickedFile!.name}';
                        final newFile = File(newPath);
                        
                        if (_pickedFile!.bytes != null) {
                          await newFile.writeAsBytes(_pickedFile!.bytes!);
                        } else if (_pickedFile!.path != null) {
                          await File(_pickedFile!.path!).copy(newPath);
                        }

                        final fileSize = (_pickedFile!.size / 1024).toStringAsFixed(1) + ' KB';

                        await _dbHelper.insertResource({
                          'title': _titleController.text,
                          'type': _selectedType,
                          'filePath': newPath,
                          'uploadDate': DateTime.now().toString(),
                          'size': fileSize,
                        });

                        await _loadResources();
                        Navigator.pop(context);
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
}