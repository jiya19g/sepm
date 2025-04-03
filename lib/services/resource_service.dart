import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class ResourceService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getResources() async {
    final response = await _supabase
        .from('resources')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<String> uploadFile(Uint8List fileBytes, String fileName) async {
    final filePath = 'resources/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await _supabase.storage
        .from('resources')
        .uploadBinary(filePath, fileBytes);
    return filePath;
  }

  Future<void> addResource(Map<String, dynamic> resource) async {
    await _supabase.from('resources').insert(resource);
  }

  Future<void> deleteResource(String id, String? filePath) async {
    if (filePath != null) {
      await _supabase.storage.from('resources').remove([filePath]);
    }
    await _supabase.from('resources').delete().eq('id', id);
  }
}