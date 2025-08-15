// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:statform/firebase_options.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Import for Hive initialization
import 'package:path_provider/path_provider.dart'; // Import for path_provider
import 'package:statform/models/match.dart';
import 'package:statform/models/team_stats_model.dart';
import 'package:statform/screens/manager_dashboard_screen.dart';
import 'package:statform/screens/match_management_screen.dart';
import 'package:statform/screens/match_screen.dart';
import 'package:statform/screens/team_creation_form.dart';
import 'package:statform/screens/team_stats_screen.dart';
import 'package:statform/screens/team_list_screen.dart'; // Added import for TeamListScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Hive
  final appDocumentDir = await getApplicationDocumentsDirectory();
  Hive.init(appDocumentDir.path);
  // Open a box for teams
  await Hive.openBox('teams');
  // Open a box for members
  await Hive.openBox('members');
  // Open a box for match records
  await Hive.openBox('matchRecords');

  runApp(const HandballApp());
}

class HandballApp extends StatelessWidget {
  const HandballApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('Building HandballApp');
    return MaterialApp(
      title: 'Handball Match Statistics',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          color: Colors.blueAccent,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
      ),
      // The home page is now the main entry point without an auth check
      home: const HomePage(),
      routes: {
        '/teamCreation': (context) => const TeamCreationForm(),
      },
      // Removed onGenerateRoute for /managerDashboard as it's now handled by TeamListScreen
      // Removed specific routes for MatchManagementScreen, TeamStatsScreen, MatchScreen from here
      // as they now require arguments and are navigated to via MaterialPageRoute
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('Building HomePage');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Handball App'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Welcome to the Handball App!',
                style: TextStyle(fontSize: 24),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  debugPrint('Navigating to MatchManagementScreen');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MatchManagementScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('Manage Teams & Start Match'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  debugPrint('Navigating to TeamCreationForm');
                  Navigator.pushNamed(context, '/teamCreation');
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('Create New Team'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  debugPrint('Navigating to TeamListScreen');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TeamListScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('Manager Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
