import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ConsultationsPage extends StatefulWidget {
  final String studentId;
  const ConsultationsPage({super.key, required this.studentId});

  @override
  State<ConsultationsPage> createState() => _ConsultationsPageState();
}

class _ConsultationsPageState extends State<ConsultationsPage> {
  List consultations = [];
  List<String> faculties = [];
  String? selectedFaculty;

  bool loading = false;

  final TextEditingController courseController = TextEditingController();
  final TextEditingController timeSlotController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchConsultations();
    fetchFaculties();
  }

  // ================= FETCH CONSULTATIONS =================
  Future<void> fetchConsultations() async {
    setState(() => loading = true);

    final host = Platform.isAndroid ? "10.0.2.2" : "127.0.0.1";
    final url =
        Uri.parse("http://$host:8000/consultations/${widget.studentId}");

    try {
      final response = await http.get(url);
      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        setState(() {
          consultations = data['consultations'];
        });
      }
    } catch (e) {
      debugPrint("Consultation error: $e");
    }

    setState(() => loading = false);
  }

  // ================= FETCH FACULTIES =================
  Future<void> fetchFaculties() async {
    final host = Platform.isAndroid ? "10.0.2.2" : "127.0.0.1";
    final url = Uri.parse("http://$host:8000/faculties");

    try {
      final response = await http.get(url);
      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        setState(() {
          faculties = List<String>.from(
            data['faculties'].map((f) => f['f_initial']),
          );
        });
      }
    } catch (e) {
      debugPrint("Faculty fetch error: $e");
    }
  }

  // ================= BOOK CONSULTATION =================
  Future<void> bookConsultation() async {
    if (selectedFaculty == null ||
        courseController.text.isEmpty ||
        timeSlotController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all fields")),
      );
      return;
    }

    final host = Platform.isAndroid ? "10.0.2.2" : "127.0.0.1";
    final url = Uri.parse("http://$host:8000/consultations");

    final body = {
      "student_id": widget.studentId,
      "course_name": courseController.text.trim(),
      "faculty_name": selectedFaculty,
      "time_slot": timeSlotController.text.trim(),
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        Navigator.pop(context);
        fetchConsultations();
      }
    } catch (e) {
      debugPrint("Booking error: $e");
    }
  }

  // ================= BOOKING DIALOG =================
  void showBookingDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Book Consultation"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: courseController,
                decoration: const InputDecoration(labelText: "Course Name"),
              ),
              const SizedBox(height: 12),

              // ✅ WORKING DROPDOWN
              DropdownButtonFormField<String>(
                value: selectedFaculty,
                items: faculties
                    .map(
                      (f) => DropdownMenuItem(
                        value: f,
                        child: Text(f),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedFaculty = value;
                  });
                },
                decoration: const InputDecoration(
                  labelText: "Faculty Initial",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),
              TextField(
                controller: timeSlotController,
                decoration: const InputDecoration(labelText: "Time Slot"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: bookConsultation,
              child: const Text("Book"),
            ),
          ],
        );
      },
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return consultations.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("No Consultations Pending"),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: showBookingDialog,
                  child: const Text("Book Consultation"),
                ),
              ],
            ),
          )
        : Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: consultations.length,
                  itemBuilder: (_, index) {
                    final c = consultations[index];
                    return ListTile(
                      title:
                          Text("${c['course_name']} - ${c['faculty_name']}"),
                      subtitle: Text(c['time_slot']),
                      trailing: Text(
                        c['status'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: showBookingDialog,
                  child: const Text("Book Consultation"),
                ),
              ),
            ],
          );
  }
}
