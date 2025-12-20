import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class UploadNotesPage extends StatefulWidget {
  const UploadNotesPage({super.key});

  @override
  State<UploadNotesPage> createState() => _UploadNotesPageState();
}

class _UploadNotesPageState extends State<UploadNotesPage> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final userIdController = TextEditingController();
  final courseController = TextEditingController();
  
  File? selectedFile;
  bool uploading = false;

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'ppt', 'pptx','jpg','jpeg','png'],
    );

    if (result != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> uploadNote() async {
    if (titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter title')),
      );
      return;
    }
    
    if (courseController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter course')),
      );
      return;
    }
    
    if (userIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your user ID')),
      );
      return;
    }
    
    if (selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file')),
      );
      return;
    }

    setState(() {
      uploading = true;
    });

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://10.0.2.2:8000/api/notes/upload'),
    );

    request.fields['title'] = titleController.text;
    request.fields['description'] = descriptionController.text;
    request.fields['course'] = courseController.text;
    request.fields['uploader_id'] = userIdController.text;
    request.files.add(await http.MultipartFile.fromPath('file', selectedFile!.path));

    var response = await request.send();

    setState(() {
      uploading = false;
    });

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note uploaded!')),
      );
      titleController.clear();
      descriptionController.clear();
      userIdController.clear();
      courseController.clear();
      setState(() {
        selectedFile = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
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
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: courseController,
                decoration: const InputDecoration(
                  labelText: 'Course (e.g., CSE 101, PHY 201)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: userIdController,
                decoration: const InputDecoration(
                  labelText: 'Your User ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
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
                ),
                child: uploading
                    ? const Text('Uploading...')
                    : const Text('Upload Note'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}