// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:statform/firebase_options.dart';
import 'package:statform/models/match.dart';
import 'package:statform/models/team_stats_model.dart';
import 'package:statform/screens/handball_form_screen.dart';
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
        '/handballForm': (context) => const HandballFormScreen(),
        '/matchManagement': (context) => const MatchManagementScreen(),
        '/teamCreation': (context) => const TeamCreationForm(),
      },
      // Removed onGenerateRoute for /managerDashboard as it's now handled by TeamListScreen
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
                  debugPrint('Navigating to HandballFormScreen');
                  Navigator.pushNamed(context, '/handballForm');
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('Open Match Form'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  debugPrint('Navigating to MatchManagementScreen');
                  Navigator.pushNamed(context, '/matchManagement');
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
