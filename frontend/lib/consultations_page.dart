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
  bool loading = false;

  // Form controllers for booking new consultation
  final TextEditingController courseController = TextEditingController();
  final TextEditingController facultyController = TextEditingController();
  final TextEditingController timeSlotController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchConsultations();
  }

  Future<void> fetchConsultations() async {
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? "Failed to fetch consultations")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Server error: $e")),
      );
    }

    setState(() => loading = false);
  }

  Future<void> bookConsultation() async {
    final host = Platform.isAndroid ? "10.0.2.2" : "127.0.0.1";
    final url = Uri.parse("http://$host:8000/consultations");

    final body = {
      "student_id": widget.studentId,
      "course_name": courseController.text.trim(),
      "faculty_name": facultyController.text.trim(),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Consultation booked successfully")),
        );
        courseController.clear();
        facultyController.clear();
        timeSlotController.clear();
        fetchConsultations(); // refresh list
        Navigator.pop(context); // close booking modal
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? "Booking failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Server error: $e")),
      );
    }
  }

  void showBookingDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Book New Consultation"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: courseController,
                  decoration: const InputDecoration(labelText: "Course Name"),
                ),
                TextField(
                  controller: facultyController,
                  decoration: const InputDecoration(labelText: "Faculty Name"),
                ),
                TextField(
                  controller: timeSlotController,
                  decoration: const InputDecoration(labelText: "Time Slot"),
                ),
              ],
            ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Consultations")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : consultations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "No Consultations Pending",
                        style: TextStyle(fontSize: 18),
                      ),
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
                        itemBuilder: (context, index) {
                          final c = consultations[index];
                          return ListTile(
                            title: Text("${c['course_name']} - ${c['faculty_name']}"),
                            subtitle: Text(c['time_slot']),
                            trailing: Text(
                              c['status'],
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        onPressed: showBookingDialog,
                        child: const Text("Book Consultation"),
                      ),
                    ),
                  ],
                ),
    );
  }
}
