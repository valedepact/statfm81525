// lib/screens/match_management_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:statform/models/match.dart';
import 'package:statform/models/team_stats_model.dart';
import 'package:statform/screens/match_screen.dart';

class MatchManagementScreen extends StatefulWidget {
  const MatchManagementScreen({super.key});

  @override
  State<MatchManagementScreen> createState() => _MatchManagementScreenState();
}

class _MatchManagementScreenState extends State<MatchManagementScreen> {
  // These will store the selected team documents
  DocumentSnapshot? _selectedHomeTeamDoc;
  DocumentSnapshot? _selectedAwayTeamDoc;

  @override
  Widget build(BuildContext context) {
    // StreamBuilder listens for real-time changes in the 'teams' collection
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('teams').snapshots(),
      builder: (context, snapshot) {
        // Show a loading indicator while the data is being fetched
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Manage Teams'), centerTitle: true),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // Handle errors
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Manage Teams'), centerTitle: true),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        // Handle the case where there are no teams
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Manage Teams'), centerTitle: true),
            body: const Center(child: Text('No teams found. Please create a team first.')),
          );
        }

        // Extract the team data from the snapshot
        final teams = snapshot.data!.docs;
        final teamNames = teams.map((doc) => doc['teamName'] as String).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Manage Teams'),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Select Home Team',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  value: _selectedHomeTeamDoc?['teamName'] as String?,
                  items: teamNames.map((name) {
                    return DropdownMenuItem(
                      value: name,
                      child: Text(name),
                    );
                  }).toList(),
                  onChanged: (String? newName) {
                    setState(() {
                      if (newName != null) {
                        _selectedHomeTeamDoc = teams.firstWhere((doc) => doc['teamName'] == newName);
                      }
                    });
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'Select Away Team',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  value: _selectedAwayTeamDoc?['teamName'] as String?,
                  items: teamNames.map((name) {
                    return DropdownMenuItem(
                      value: name,
                      child: Text(name),
                    );
                  }).toList(),
                  onChanged: (String? newName) {
                    setState(() {
                      if (newName != null) {
                        _selectedAwayTeamDoc = teams.firstWhere((doc) => doc['teamName'] == newName);
                      }
                    });
                  },
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _selectedHomeTeamDoc != null && _selectedAwayTeamDoc != null
                      ? () {
                    if (_selectedHomeTeamDoc != null && _selectedAwayTeamDoc != null) {
                      final homeTeam = TeamStats.fromFirestore(_selectedHomeTeamDoc!);
                      final awayTeam = TeamStats.fromFirestore(_selectedAwayTeamDoc!);
                      final newMatch = Match(
                        homeTeam: homeTeam,
                        awayTeam: awayTeam,
                      );

                      debugPrint('Starting match with Home Team ID: ${_selectedHomeTeamDoc!.id} and Away Team ID: ${_selectedAwayTeamDoc!.id}');

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MatchScreen(
                            match: newMatch,
                            homeTeamId: _selectedHomeTeamDoc!.id,
                            awayTeamId: _selectedAwayTeamDoc!.id,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select both home and away teams.')),
                      );
                    }
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  child: const Text('Start Match'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
