import 'package:flutter/material.dart';

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
  int _selectedIndex = 0;

  final List<String> _titles = [
    'My Routine',
    'Others Routine',
    'Upload Notes',
    'Browse Notes',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              "D://Codes//flutter_proj//homepage_demo//assets//logo.png",
              height: 40,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.school, size: 40);
              },
            ),
            const SizedBox(width: 12),
            const Text(
              'Academic Life Management',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
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
                icon: Icon(Icons.library_books),
                label: Text('Browse Notes'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
        ],
      ),
    );
  }
}