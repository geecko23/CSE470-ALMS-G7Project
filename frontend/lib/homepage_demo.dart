import 'package:flutter/material.dart';
import 'notes/upload_notes.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Academic Hub',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedPage = 0;

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
            ],
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
    if (selectedPage == 0) {
      return const Center(child: Text('My Routine Page'));
    } else if (selectedPage == 1) {
      return const Center(child: Text('Others Routine Page'));
    } else if (selectedPage == 2) {
      return const UploadNotesPage();
      } else if (selectedPage == 3) {
        return const Center(child: Text('Others Routine Page'));
      } else {
        return const Center(child: Text('Others Routine Page'));
      }
  }
}