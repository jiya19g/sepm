import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;

  PdfViewerScreen({required this.pdfUrl});

  @override
  _PdfViewerScreenState createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late PdfController _pdfController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      final fileBytes = await Supabase.instance.client.storage
          .from('resources')
          .download(widget.pdfUrl);
      
      _pdfController = PdfController(
        document: PdfDocument.openData(fileBytes),
      );
      
      setState(() => _isLoading = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading PDF: $e')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('PDF Viewer')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : PdfView(controller: _pdfController),
    );
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }
}