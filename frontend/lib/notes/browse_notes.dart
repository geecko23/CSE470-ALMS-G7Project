import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'file_viewer_page.dart';

class BrowseNotesPage extends StatefulWidget {
  final String studentId;
  const BrowseNotesPage({super.key, required this.studentId});

  @override
  State<BrowseNotesPage> createState() => _BrowseNotesPageState();
}

class _BrowseNotesPageState extends State<BrowseNotesPage> {
  List<dynamic> allNotes = [];
  List<dynamic> filteredNotes = [];
  bool loading = true;
  String? errorMessage;
  String searchQuery = '';
  String selectedCourse = 'All';

  @override
  void initState() {
    super.initState();
    fetchAllNotes();
  }

  Future<void> fetchAllNotes() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    final host = Platform.isAndroid ? "10.0.2.2" : "127.0.0.1";
    final url = Uri.parse("http://$host:8000/api/notes/all");

    try {
      final response = await http.get(url);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["success"] == true) {
        setState(() {
          allNotes = data["notes"];
          filteredNotes = allNotes;
          loading = false;
        });
      } else {
        setState(() {
          errorMessage = data["error"] ?? "Failed to load notes";
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Server error: $e";
        loading = false;
      });
    }
  }

  void filterNotes() {
    setState(() {
      filteredNotes = allNotes.where((note) {
        final matchesSearch = note['title']
                .toString()
                .toLowerCase()
                .contains(searchQuery.toLowerCase()) ||
            note['description']
                .toString()
                .toLowerCase()
                .contains(searchQuery.toLowerCase());

        final matchesCourse = selectedCourse == 'All' ||
            note['course'].toString().toUpperCase().contains(selectedCourse);

        return matchesSearch && matchesCourse;
      }).toList();
    });
  }

  void viewNote(Map<String, dynamic> note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FileViewerPage(
          filename: note['filename'],
          title: note['title'] ?? 'Document',
        ),
      ),
    );
  }

  String formatFileSize(int bytes) {
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
  }

  String formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateStr);
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return dateStr;
    }
  }
  Future<void> saveNote(int noteId) async {
  final host = Platform.isAndroid ? "10.0.2.2" : "127.0.0.1";
  final url = Uri.parse("http://$host:8000/api/notes/save");

  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": widget.studentId, 
        "note_id": noteId,
      }),
    );
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data["success"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note saved successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data["message"] ?? "Failed to save note")),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e")),
    );
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color.fromRGBO(126, 194, 250, 1),
                  Color.fromRGBO(126, 194, 250, 0.6),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Browse Notes',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Explore notes from all students',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: fetchAllNotes,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search bar
                TextField(
                  onChanged: (value) {
                    searchQuery = value;
                    filterNotes();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search notes...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Course filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'CSE', 'MAT', 'PHY'].map((course) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(course),
                          selected: selectedCourse == course,
                          onSelected: (selected) {
                            setState(() {
                              selectedCourse = course;
                              filterNotes();
                            });
                          },
                          selectedColor: Colors.white,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          labelStyle: TextStyle(
                            color: selectedCourse == course
                                ? const Color.fromRGBO(126, 194, 250, 1)
                                : Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Notes list
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 60, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              errorMessage!,
                              style: const TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: fetchAllNotes,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : filteredNotes.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off,
                                    size: 80, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'No notes found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredNotes.length,
                            itemBuilder: (context, index) {
                              final note = filteredNotes[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: InkWell(
                                  onTap: () => viewNote(note),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Icon
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color.fromRGBO(126, 194, 250, 1),
                                                Color.fromRGBO(126, 194, 250, 0.6),
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.description,
                                            color: Colors.white,
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(width: 16),

                                        // Content
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                note['title'] ?? 'Untitled',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                note['description'] ??
                                                    'No description',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 4,
                                                children: [
                                                  _buildChip(
                                                    Icons.subject,
                                                    note['course'] ?? 'N/A',
                                                  ),
                                                  _buildChip(
                                                    Icons.person,
                                                    note['uploader_name'] ??
                                                        'Unknown',
                                                  ),
                                                  _buildChip(
                                                    Icons.storage,
                                                    formatFileSize(
                                                        note['file_size'] ?? 0),
                                                  ),
                                                  _buildChip(
                                                    Icons.calendar_today,
                                                    formatDate(
                                                        note['upload_date']),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),

                                        Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.bookmark_add),
                                                onPressed: () => saveNote(note['id']),
                                                color: const Color.fromRGBO(126, 194, 250, 1),
                                                tooltip: 'Save',
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.visibility),
                                                onPressed: () => viewNote(note),
                                                color: const Color.fromRGBO(126, 194, 250, 1),
                                                tooltip: 'View',
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(126, 194, 250, 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color.fromRGBO(126, 194, 250, 1)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color.fromRGBO(126, 194, 250, 1),
            ),
          ),
        ],
      ),
    );
  }
}