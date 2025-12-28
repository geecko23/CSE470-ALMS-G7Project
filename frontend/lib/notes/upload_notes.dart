import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';

class UploadNotesPage extends StatefulWidget {
  final String studentId;
  const UploadNotesPage({super.key, required this.studentId});

  @override
  State<UploadNotesPage> createState() => _UploadNotesPageState();
}

class _UploadNotesPageState extends State<UploadNotesPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController courseController = TextEditingController();

  File? selectedFile;
  bool uploading = false;

  // ================= FILE PICKER =================
  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'doc',
        'docx',
        'txt',
        'ppt',
        'pptx',
        'jpg',
        'jpeg',
        'png'
      ],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
      });
    }
  }

  // ================= UPLOAD NOTE =================
  Future<void> uploadNote() async {
    if (titleController.text.isEmpty ||
        courseController.text.isEmpty ||
        selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and select a file')),
      );
      return;
    }

    setState(() => uploading = true);

    final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
    final url = Uri.parse('http://$host:8000/api/notes/upload');

    var request = http.MultipartRequest('POST', url);

    request.fields['title'] = titleController.text.trim();
    request.fields['description'] = descriptionController.text.trim();
    request.fields['course'] = courseController.text.trim();
    request.fields['uploader_id'] = widget.studentId;

    request.files.add(await http.MultipartFile.fromPath('file', selectedFile!.path));

    try {
      var response = await request.send();
      final responseData = await http.Response.fromStream(response);

      final data = jsonDecode(responseData.body);

      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note uploaded successfully!')),
        );
        // Clear inputs
        titleController.clear();
        descriptionController.clear();
        courseController.clear();
        setState(() => selectedFile = null);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${data['error'] ?? responseData.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Server error: $e')),
      );
    } finally {
      setState(() => uploading = false);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Upload Notes',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _inputField(titleController, 'Title'),
              const SizedBox(height: 15),
              _inputField(descriptionController, 'Description', maxLines: 3),
              const SizedBox(height: 15),
              _inputField(courseController, 'Course (e.g., CSE 101, PHY 201)'),
              const SizedBox(height: 15),
              OutlinedButton.icon(
                onPressed: pickFile,
                icon: const Icon(Icons.attach_file),
                label: Text(
                  selectedFile == null
                      ? 'Choose File'
                      : 'File: ${selectedFile!.path.split('/').last}',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(15),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: uploading ? null : uploadNote,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(15),
                  backgroundColor: const Color.fromRGBO(126, 194, 250, 1),
                ),
                child: uploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Upload Note',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField(TextEditingController controller, String label,
      {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
