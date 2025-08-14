// lib/screens/team_management_login_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:statform/screens/manager_dashboard_screen.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class TeamManagementLoginScreen extends StatefulWidget {
  const TeamManagementLoginScreen({super.key});

  @override
  State<TeamManagementLoginScreen> createState() => _TeamManagementLoginScreenState();
}

class _TeamManagementLoginScreenState extends State<TeamManagementLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _teamNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  Future<void> _loginToTeam() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final teamName = _teamNameController.text.trim();
        final password = _passwordController.text.trim();

        // Hash the entered password for comparison
        final passwordBytes = utf8.encode(password);
        final hashedPassword = sha256.convert(passwordBytes).toString();

        // Query Firestore to find the team by name
        final querySnapshot = await _firestore
            .collection('teams')
            .where('teamName', isEqualTo: teamName)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final teamDoc = querySnapshot.docs.first;
          final teamData = teamDoc.data();
          final storedPasswordHash = teamData['managerPasswordHash'];

          // Check if the hashed passwords match
          if (hashedPassword == storedPasswordHash) {
            // Success! Navigate to the dashboard
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ManagerDashboardScreen(teamId: teamDoc.id),
              ),
            );
          } else {
            // Password mismatch
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Incorrect password.')),
            );
          }
        } else {
          // Team not found
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Team not found.')),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Login'),
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
                'Log in to your team management dashboard:',
                style: TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _teamNameController,
                decoration: const InputDecoration(
                  labelText: 'Team Name',
                  border: OutlineInputBorder(),
                  icon: Icon(Icons.group),
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
                obscureText: true,
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
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                onPressed: _loginToTeam,
                icon: const Icon(Icons.login),
                label: const Text('Login'),
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
