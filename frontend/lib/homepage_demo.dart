import 'package:flutter/material.dart';
import 'consultations_page.dart';
import 'notes/upload_notes.dart';
import 'notes/mynotes.dart';
import 'notes/browse_notes.dart';


class HomePage extends StatefulWidget {
  final String studentId; // logged-in student ID
  const HomePage({super.key, required this.studentId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedPage = 0;

  void logout() {
    // Remove all previous routes and go back to login page
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.school, size: 40),
            SizedBox(width: 12),
            Text('Academic Hub'),
          ],
        ),
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedPage,
            onDestinationSelected: (index) {
              setState(() {
                selectedPage = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.calendar_today),
                label: Text('My Routine'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people),
                label: Text('Others Routine'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.note_add),
                label: Text('Upload Notes'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.description),
                label: Text('My Notes'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.library_books),
                label: Text('Browse Notes'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.access_time),
                label: Text('Consultations'),
              ),
            ],
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Divider(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: IconButton(
                    tooltip: 'Logout',
                    icon: const Icon(
                      Icons.logout,
                      color: Colors.red,
                    ),
                    onPressed: logout,
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _showPage(),
          ),
        ],
      ),
    );
  }

  Widget _showPage() {
    switch (selectedPage) {
      case 0:
        return const Center(child: Text('My Routine Page'));
      case 1:
        return const Center(child: Text('Others Routine Page'));
      case 2:
        return UploadNotesPage(studentId: widget.studentId);
      case 3:
        return MyNotesPage(studentId: widget.studentId);
      case 4:
        return const BrowseNotesPage();
      case 5:
        return ConsultationsPage(studentId: widget.studentId);
      default:
        return const Center(child: Text('Page not found')); 
    }
  }
}
