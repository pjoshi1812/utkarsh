import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:url_launcher/url_launcher.dart';

class ContentViewerScreen extends StatefulWidget {
  final String title;
  final String fileUrl;
  final String fileType; // extension like pdf, jpg, png

  const ContentViewerScreen({super.key, required this.title, required this.fileUrl, required this.fileType});

  @override
  State<ContentViewerScreen> createState() => _ContentViewerScreenState();
}

class _ContentViewerScreenState extends State<ContentViewerScreen> {
  String? _localPath; // downloaded temp file for PDF
  bool _loading = true;
  String? _error;

  bool get _isImage {
    final ext = widget.fileType.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
  }

  bool get _isPdf => widget.fileType.toLowerCase() == 'pdf';

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void dispose() {
    try {
      if (!kIsWeb) {
        ScreenProtector.preventScreenshotOff();
      }
    } catch (_) {}
    super.dispose();
  }

  Future<void> _prepare() async {
    try {
      // Block screenshots/recording on mobile only
      if (!kIsWeb) {
        await ScreenProtector.preventScreenshotOn();
      }

      // Validate URL once
      final String url = widget.fileUrl.trim();
      final Uri? uri = Uri.tryParse(url);
      final bool valid = url.isNotEmpty &&
          uri != null &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          (kIsWeb || uri.host.isNotEmpty);

      if (!valid) {
        setState(() {
          _error = 'Invalid file URL.';
          _loading = false;
        });
        return;
      }

      if (_isPdf) {
        if (kIsWeb) {
          // Web: open in a new tab using the browser (use pre-validated uri)
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          setState(() {
            _loading = false;
          });
          return;
        }

        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/temp_${DateTime.now().millisecondsSinceEpoch}.pdf');

        // Use pre-validated uri
        final resp = await http.get(uri);
        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          await file.writeAsBytes(resp.bodyBytes);
          setState(() {
            _localPath = file.path;
            _loading = false;
          });
        } else {
          setState(() {
            _error = 'Failed to load PDF (${resp.statusCode})';
            _loading = false;
          });
        }
      } else if (_isImage) {
        // Images load directly via network in PhotoView
        setState(() {
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Unsupported file type: ${widget.fileType}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error preparing viewer: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title, overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(_error!, style: const TextStyle(color: Colors.white)),
                  ),
                )
              : _isImage
                  ? PhotoView(
                      backgroundDecoration: const BoxDecoration(color: Colors.black),
                      imageProvider: NetworkImage(widget.fileUrl),
                    )
                  : _isPdf
                      ? _buildPdf()
                      : const SizedBox.shrink(),
    );
  }

  Widget _buildPdf() {
    if (_localPath == null) {
      return const Center(child: Text('Failed to load PDF', style: TextStyle(color: Colors.white)));
    }
    return PDFView(
      filePath: _localPath!,
      swipeHorizontal: true,
      enableSwipe: true,
      autoSpacing: true,
      pageFling: true,
      onError: (e) {},
    );
  }
}