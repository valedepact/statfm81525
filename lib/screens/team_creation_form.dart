// lib/screens/team_creation_form.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:statform/screens/manager_dashboard_screen.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert'; // For utf8.encode
import 'package:hive_flutter/hive_flutter.dart'; // Import for Hive

class TeamCreationForm extends StatefulWidget {
  const TeamCreationForm({super.key});

  @override
  State<TeamCreationForm> createState() => _TeamCreationFormState();
}

class _TeamCreationFormState extends State<TeamCreationForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _teamNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController(); // New controller for password confirmation
  // The firestore instance is defined here
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // A function to handle the team creation
  Future<void> _createTeam() async {
    // Check if the form is valid
    if (_formKey.currentState!.validate()) {
      // Hash the password for secure storage
      final passwordBytes = utf8.encode(_passwordController.text.trim());
      final hashedPassword = sha256.convert(passwordBytes).toString();

      // Prepare the data for Firestore
      final newTeamData = {
        'teamName': _teamNameController.text.trim(),
        'managerPasswordHash': hashedPassword, // Store the hashed password
        'createdAt': FieldValue.serverTimestamp(),
      };

      try {
        // Correctly reference the public collection path
        final publicTeamsCollection = _firestore.collection('teams');

        // Add the new team document to the public 'teams' collection
        final docRef = await publicTeamsCollection.add(newTeamData);

        // Save to Hive for offline access
        final teamsBox = Hive.box('teams');
        await teamsBox.put(docRef.id, newTeamData); // Use Firestore ID as Hive key

        // Check if the widget is still mounted before showing the snackbar or navigating
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Team created successfully!')),
        );

        // Navigate to the manager dashboard for the newly created team
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ManagerDashboardScreen(teamId: docRef.id),
          ),
        );
      } catch (e) {
        // Check if the widget is still mounted before showing the snackbar
        if (!context.mounted) return;

        // Handle any errors that occur during the Firestore write
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating team: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create a New Team'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Enter the name and password for your new team:',
                style: TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _teamNameController,
                decoration: const InputDecoration(
                  labelText: 'Team Name',
                  border: OutlineInputBorder(),
                  icon: Icon(Icons.group_add),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a team name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _passwordController,
                obscureText: true, // Hide the password
                decoration: const InputDecoration(
                  labelText: 'Manager Password',
                  border: OutlineInputBorder(),
                  icon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true, // Hide the password
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
                  icon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _createTeam,
                icon: const Icon(Icons.add),
                label: const Text('Create Team'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
