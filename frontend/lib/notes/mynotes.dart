import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'file_viewer_page.dart';

class MyNotesPage extends StatefulWidget {
  final String studentId;
  const MyNotesPage({super.key, required this.studentId});

  @override
  State<MyNotesPage> createState() => _MyNotesPageState();
}

class _MyNotesPageState extends State<MyNotesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<dynamic> uploadedNotes = [];
  List<dynamic> filteredUploadedNotes = [];
  List<dynamic> savedNotes = [];
  List<dynamic> filteredSavedNotes = [];
  
  bool loadingUploaded = true;
  bool loadingSaved = true;
  String? uploadedError;
  String? savedError;
  
  String uploadedSearchQuery = '';
  String savedSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchUploadedNotes();
    fetchSavedNotes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get host => Platform.isAndroid ? "10.0.2.2" : "127.0.0.1";

  //  FETCH UPLOADED NOTES
  Future<void> fetchUploadedNotes() async {
    setState(() {
      loadingUploaded = true;
      uploadedError = null;
    });

    final url = Uri.parse("http://$host:8000/api/notes/user/${widget.studentId}");

    try {
      final response = await http.get(url);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["success"] == true) {
        setState(() {
          uploadedNotes = data["notes"];
          filteredUploadedNotes = uploadedNotes;
          loadingUploaded = false;
        });
      } else {
        setState(() {
          uploadedError = data["error"] ?? "Failed to load notes";
          loadingUploaded = false;
        });
      }
    } catch (e) {
      setState(() {
        uploadedError = "Server error: $e";
        loadingUploaded = false;
      });
    }
  }

  // FETCH SAVED NOTES 
  Future<void> fetchSavedNotes() async {
    setState(() {
      loadingSaved = true;
      savedError = null;
    });

    final url = Uri.parse("http://$host:8000/api/notes/saved/${widget.studentId}");

    try {
      final response = await http.get(url);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["success"] == true) {
        setState(() {
          savedNotes = data["notes"];
          filteredSavedNotes = savedNotes;
          loadingSaved = false;
        });
      } else {
        setState(() {
          savedError = data["error"] ?? "Failed to load saved notes";
          loadingSaved = false;
        });
      }
    } catch (e) {
      setState(() {
        savedError = "Server error: $e";
        loadingSaved = false;
      });
    }
  }

  //  UNSAVE NOTE 
  Future<void> unsaveNote(int noteId) async {
    final url = Uri.parse("http://$host:8000/api/notes/unsave/${widget.studentId}/$noteId");

    try {
      final response = await http.delete(url);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note removed from saved')),
        );
        fetchSavedNotes();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["error"] ?? "Failed to unsave note")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }
  
  
  Future<void> deleteNote(int noteId) async {
  final url = Uri.parse("http://$host:8000/api/notes/delete/${widget.studentId}/$noteId");

  try {
    final response = await http.delete(url);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data["success"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note deleted successfully'), backgroundColor: Colors.green),
      );
      fetchUploadedNotes();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data["message"] ?? "Failed to delete note"), backgroundColor: Colors.red),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
    );
  }
}

  //  FILTER UPLOADED NOTES
  void filterUploadedNotes() {
    setState(() {
      filteredUploadedNotes = uploadedNotes.where((note) {
        return note['title']
                .toString()
                .toLowerCase()
                .contains(uploadedSearchQuery.toLowerCase()) ||
            note['description']
                .toString()
                .toLowerCase()
                .contains(uploadedSearchQuery.toLowerCase()) ||
            note['course']
                .toString()
                .toLowerCase()
                .contains(uploadedSearchQuery.toLowerCase());
      }).toList();
    });
  }

  //  FILTER SAVED NOTES 
  void filterSavedNotes() {
    setState(() {
      filteredSavedNotes = savedNotes.where((note) {
        return note['title']
                .toString()
                .toLowerCase()
                .contains(savedSearchQuery.toLowerCase()) ||
            note['description']
                .toString()
                .toLowerCase()
                .contains(savedSearchQuery.toLowerCase()) ||
            note['course']
                .toString()
                .toLowerCase()
                .contains(savedSearchQuery.toLowerCase());
      }).toList();
    });
  }

  //  VIEW NOTE 
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
  

  // FILE SIZE FORMAT 
  String formatFileSize(int bytes) {
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
  }

  // UI 
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
                          'My Notes',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Manage your notes collection',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: () {
                        fetchUploadedNotes();
                        fetchSavedNotes();
                      },
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Tabs
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  tabs: const [
                    Tab(text: 'Uploaded Notes'),
                    Tab(text: 'Saved Notes'),
                  ],
                ),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUploadedTab(),
                _buildSavedTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // UPLOADED NOTES TAB
  Widget _buildUploadedTab() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (value) {
              uploadedSearchQuery = value;
              filterUploadedNotes();
            },
            decoration: InputDecoration(
              hintText: 'Search uploaded notes...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),

        // Notes list
        Expanded(
          child: loadingUploaded
              ? const Center(child: CircularProgressIndicator())
              : uploadedError != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 60, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(uploadedError!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: fetchUploadedNotes,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : filteredUploadedNotes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.note_add_outlined, size: 80, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                uploadedSearchQuery.isEmpty
                                    ? 'No notes uploaded yet'
                                    : 'No notes found',
                                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredUploadedNotes.length,
                          itemBuilder: (context, index) {
                            final note = filteredUploadedNotes[index];
                            return _buildNoteCard(note, isUploaded: true);
                          },
                        ),
        ),
      ],
    );
  }

  // SAVED NOTES TAB 
  Widget _buildSavedTab() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (value) {
              savedSearchQuery = value;
              filterSavedNotes();
            },
            decoration: InputDecoration(
              hintText: 'Search saved notes...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),

        // Notes list
        Expanded(
          child: loadingSaved
              ? const Center(child: CircularProgressIndicator())
              : savedError != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 60, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(savedError!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: fetchSavedNotes,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : filteredSavedNotes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.bookmark_border, size: 80, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                savedSearchQuery.isEmpty
                                    ? 'No saved notes yet'
                                    : 'No notes found',
                                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                              ),
                              if (savedSearchQuery.isEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Save notes from Browse Notes page',
                                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                                ),
                              ],
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredSavedNotes.length,
                          itemBuilder: (context, index) {
                            final note = filteredSavedNotes[index];
                            return _buildNoteCard(note, isUploaded: false);
                          },
                        ),
        ),
      ],
    );
  }

  // NOTE CARD 
  Widget _buildNoteCard(Map<String, dynamic> note, {required bool isUploaded}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromRGBO(126, 194, 250, 1),
            Color.fromRGBO(126, 194, 250, 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const Icon(Icons.description, color: Colors.white, size: 32),
        title: Text(
          note['title'] ?? 'Untitled',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              note['description'] ?? 'No description',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(126, 194, 250, 0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    note['course'] ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatFileSize(note['file_size'] ?? 0),
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
                if (!isUploaded && note['uploader_name'] != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    'by ${note['uploader_name']}',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility, color: Colors.white),
              onPressed: () => viewNote(note),
              tooltip: 'View',
            ),
            if (isUploaded)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                onPressed: () => deleteNote(note['id']),
                tooltip: 'Delete',
              )
            else
              IconButton(
                icon: const Icon(Icons.bookmark_remove, color: Colors.white),
                onPressed: () => unsaveNote(note['id']),
                tooltip: 'Unsave',
              ),
          ],
        ),
      ),
    );
  }
}