import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:studybuddy_app/screens/pdf_viewer_screen.dart';

class ResourceDetailScreen extends StatelessWidget {
  final Map<String, dynamic> resource;
  final VoidCallback? onDelete;

  const ResourceDetailScreen({
    required this.resource,
    this.onDelete,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isOwner = resource['user_id'] == FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(resource['title'], style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black54),
        actions: [
          if (isOwner)
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteResource(context),
            ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: _getTypeColor(resource['type']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Icon(
                    resource['type'] == 'PDF' 
                      ? Icons.picture_as_pdf 
                      : resource['type'] == 'Video'
                        ? Icons.video_library
                        : Icons.link,
                    color: _getTypeColor(resource['type']),
                    size: 48,
                  ),
                ),
              ),
            ),
            SizedBox(height: 32),
            Text(
              resource['title'],
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Uploaded by ${resource['user_id']}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDetailItem(Icons.calendar_today, 
                  _formatDate(resource['created_at'])),
                _buildDetailItem(Icons.sd_storage, resource['size'] ?? ''),
                _buildDetailItem(
                  resource['type'] == 'PDF' 
                    ? Icons.picture_as_pdf 
                    : resource['type'] == 'Video'
                      ? Icons.video_library
                      : Icons.link,
                  resource['type']),
              ],
            ),
            SizedBox(height: 24),
            if ((resource['tags'] as List<dynamic>?)?.isNotEmpty ?? false)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tags:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: (resource['tags'] as List<dynamic>)
                        .whereType<String>()
                        .map<Widget>((tag) => Chip(
                          label: Text(tag),
                        )).toList(),
                  ),
                  SizedBox(height: 24),
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
                onPressed: () => _openResource(context),
                child: Text(
                  resource['type'] == 'Link' 
                    ? 'OPEN LINK' 
                    : 'OPEN ${resource['type']}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
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
        Icon(icon, color: Colors.grey[600], size: 24),
        SizedBox(height: 8),
        Text(
          text,
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ],
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
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _openResource(BuildContext context) async {
    try {
      if (resource['type'] == 'PDF' && resource['file_path'] != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PdfViewerScreen(
              pdfUrl: resource['file_path'],
            ),
          ),
        );
      } else if (resource['type'] == 'Video' && resource['file_path'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Video player will be implemented here')),
        );
      } else if (resource['type'] == 'Link' && resource['url'] != null) {
        if (!await launchUrl(Uri.parse(resource['url']))) {
          throw Exception('Could not launch ${resource['url']}');
        }
      } else {
        throw Exception('Resource type not supported');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening resource: $e')),
      );
    }
  }

  Future<void> _deleteResource(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Resource'),
        content: Text('Are you sure you want to delete this resource?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    try {
      final supabase = Supabase.instance.client;
      
      if (resource['file_path'] != null) {
        await supabase.storage
            .from('resources')
            .remove([resource['file_path']]);
      }
      
      await supabase
          .from('resources')
          .delete()
          .eq('id', resource['id']);
      
      if (onDelete != null) onDelete!();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting resource: $e')),
      );
    }
  }
}