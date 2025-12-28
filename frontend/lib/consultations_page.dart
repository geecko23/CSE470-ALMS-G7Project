import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ConsultationsPage extends StatefulWidget {
  final String studentId; // for students, faculty ID also works
  const ConsultationsPage({super.key, required this.studentId});

  @override
  State<ConsultationsPage> createState() => _ConsultationsPageState();
}

class _ConsultationsPageState extends State<ConsultationsPage> {
  bool loading = true;
  bool isFaculty = false;
  String? facultyInitial;
  List consultations = [];
  List<String> faculties = [];
  String? selectedFaculty;

  final TextEditingController courseController = TextEditingController();
  final TextEditingController timeSlotController = TextEditingController();

  @override
  void initState() {
    super.initState();
    checkUserType();
    fetchFaculties();
  }

  // =================== CHECK USER TYPE ===================
  Future<void> checkUserType() async {
    final host = Platform.isAndroid ? "10.0.2.2" : "127.0.0.1";
    final url = Uri.parse("http://$host:8000/faculty/${widget.studentId}");

    try {
      final response = await http.get(url);
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        setState(() {
          isFaculty = true;
          facultyInitial = data['faculty']['f_initial'];
        });
        fetchFacultyConsultations();
      } else {
        // student
        setState(() {
          isFaculty = false;
        });
        fetchStudentConsultations();
      }
    } catch (e) {
      debugPrint("User type check error: $e");
    }
  }

  // =================== FETCH FACULTIES ===================
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

  // =================== FETCH CONSULTATIONS ===================
  Future<void> fetchStudentConsultations() async {
    setState(() => loading = true);
    final host = Platform.isAndroid ? "10.0.2.2" : "127.0.0.1";
    final url = Uri.parse("http://$host:8000/consultations/${widget.studentId}");

    try {
      final response = await http.get(url);
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        setState(() {
          consultations = data['consultations'];
        });
      }
    } catch (e) {
      debugPrint("Student consultation error: $e");
    }
    setState(() => loading = false);
  }

  Future<void> fetchFacultyConsultations() async {
    setState(() => loading = true);
    if (facultyInitial == null) return;

    final host = Platform.isAndroid ? "10.0.2.2" : "127.0.0.1";
    final url = Uri.parse("http://$host:8000/consultations/faculty/$facultyInitial");

    try {
      final response = await http.get(url);
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        setState(() {
          consultations = data['consultations'];
        });
      }
    } catch (e) {
      debugPrint("Faculty consultation error: $e");
    }
    setState(() => loading = false);
  }

  // =================== BOOK CONSULTATION (STUDENTS ONLY) ===================
  Future<void> bookConsultation() async {
    if (selectedFaculty == null || courseController.text.isEmpty || timeSlotController.text.isEmpty) {
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
      final response = await http.post(url, headers: {"Content-Type": "application/json"}, body: jsonEncode(body));
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        Navigator.pop(context);
        fetchStudentConsultations();
        courseController.clear();
        timeSlotController.clear();
        selectedFaculty = null;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['error'] ?? "Booking failed")));
      }
    } catch (e) {
      debugPrint("Booking error: $e");
    }
  }

  void showBookingDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Book Consultation"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: courseController,
              decoration: const InputDecoration(labelText: "Course Name"),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedFaculty,
              items: faculties.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
              onChanged: (value) => setState(() => selectedFaculty = value),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(126, 194, 250, 1),
            ),
            onPressed: bookConsultation,
            child: const Text("Book"),
          ),
        ],
      ),
    );
  }

  // =================== UPDATE STATUS (FACULTY ONLY) ===================
  Future<void> updateStatus(int consultationId, String newStatus) async {
    final host = Platform.isAndroid ? "10.0.2.2" : "127.0.0.1";
    final url = Uri.parse("http://$host:8000/consultations/update_status?consultation_id=$consultationId&status=$newStatus");

    try {
      final response = await http.put(url);
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        fetchFacultyConsultations();
      }
    } catch (e) {
      debugPrint("Update status error: $e");
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "accepted":
        return Colors.green;
      case "pending":
        return Colors.orange;
      case "declined":
        return Colors.red;
      case "completed":
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        Expanded(
          child: consultations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("No Consultations Pending"),
                      if (!isFaculty)
                        const SizedBox(height: 20),
                      if (!isFaculty)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromRGBO(126, 194, 250, 1),
                          ),
                          onPressed: showBookingDialog,
                          child: const Text("Book Consultation"),
                        ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: consultations.length,
                  itemBuilder: (_, index) {
                    final c = consultations[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color.fromRGBO(126, 194, 250, 1),
                            Color.fromRGBO(126, 194, 250, 0.6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${c['course_name']} - ${c['faculty_name']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text("Time: ${c['time_slot']}"),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text("Status: "),
                              isFaculty
                                  ? DropdownButton<String>(
                                      value: c['status'],
                                      items: ["pending", "accepted", "declined", "completed"]
                                          .map((s) => DropdownMenuItem(
                                                value: s,
                                                child: Text(
                                                  s,
                                                  style: TextStyle(color: getStatusColor(s)),
                                                ),
                                              ))
                                          .toList(),
                                      onChanged: (value) {
                                        if (value != null) updateStatus(c['id'], value);
                                      },
                                    )
                                  : Text(
                                      c['status'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: getStatusColor(c['status']),
                                      ),
                                    ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        if (!isFaculty && consultations.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(126, 194, 250, 1),
              ),
              onPressed: showBookingDialog,
              child: const Text("Book Consultation"),
            ),
          ),
      ],
    );
  }
}
