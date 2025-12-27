import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class FileViewerPage extends StatefulWidget {
  final String filename;
  final String title;

  const FileViewerPage({
    super.key,
    required this.filename,
    required this.title,
  });

  @override
  State<FileViewerPage> createState() => _FileViewerPageState();
}

class _FileViewerPageState extends State<FileViewerPage> {
  String? localPath;
  bool loading = true;
  String? errorMessage;
  int totalPages = 0;
  int currentPage = 0;
  String fileType = '';

  @override
  void initState() {
    super.initState();
    fileType = _getFileType();
    downloadFile();
  }

  String _getFileType() {
    final filename = widget.filename.toLowerCase();
    if (filename.endsWith('.pdf')) return 'pdf';
    if (filename.endsWith('.jpg') || filename.endsWith('.jpeg') || filename.endsWith('.png')) return 'image';
    return 'unsupported';
  }

  Future<void> downloadFile() async {
    if (fileType == 'unsupported') {
      setState(() {
        errorMessage = 'Cannot preview ${widget.filename.split('.').last.toUpperCase()} files. Only PDF and images are supported.';
        loading = false;
      });
      return;
    }

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final host = Platform.isAndroid ? "10.0.2.2" : "127.0.0.1";
      final url = "http://$host:8000/api/notes/download/${widget.filename}";

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/${widget.filename}');
        await file.writeAsBytes(response.bodyBytes);

        setState(() {
          localPath = file.path;
          loading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to download file';
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: const Color.fromRGBO(126, 194, 250, 1),
        foregroundColor: Colors.white,
        actions: [
          if (fileType == 'pdf' && totalPages > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '${currentPage + 1} / $totalPages',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
      backgroundColor: fileType == 'image' ? Colors.black : Colors.white,
      body: loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: fileType == 'image' ? Colors.white : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: TextStyle(
                      color: fileType == 'image' ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            )
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 60,
                          color: fileType == 'image' ? Colors.white : Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          errorMessage!,
                          style: TextStyle(
                            fontSize: 16,
                            color: fileType == 'image' ? Colors.white : Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (fileType != 'unsupported') ...[
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: downloadFile,
                            child: const Text('Retry'),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : localPath != null
                  ? fileType == 'pdf'
                      ? PDFView(
                          filePath: localPath!,
                          enableSwipe: true,
                          swipeHorizontal: false,
                          autoSpacing: true,
                          pageFling: true,
                          pageSnap: true,
                          onRender: (pages) {
                            setState(() {
                              totalPages = pages ?? 0;
                            });
                          },
                          onPageChanged: (page, total) {
                            setState(() {
                              currentPage = page ?? 0;
                            });
                          },
                          onError: (error) {
                            setState(() {
                              errorMessage = error.toString();
                            });
                          },
                        )
                      : InteractiveViewer(
                          minScale: 0.5,
                          maxScale: 4.0,
                          child: Center(
                            child: Image.file(
                              File(localPath!),
                              fit: BoxFit.contain,
                            ),
                          ),
                        )
                  : Center(
                      child: Text(
                        'Unable to load file',
                        style: TextStyle(
                          color: fileType == 'image' ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
    );
  }
}