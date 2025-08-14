import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:statform/screens/team_management_login_screen.dart';

class TeamListScreen extends StatelessWidget {
  const TeamListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a Team'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('teams').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No teams created yet.'));
          }

          final teams = snapshot.data!.docs;

          return ListView.builder(
            itemCount: teams.length,
            itemBuilder: (context, index) {
              final teamDoc = teams[index];
              final teamData = teamDoc.data() as Map<String, dynamic>;
              final teamName = teamData['teamName'] ?? 'Unnamed Team';
              final teamId = teamDoc.id;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.group),
                  title: Text(teamName),
                  onTap: () {
                    // Navigate to the login screen for the selected team
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TeamManagementLoginScreen(
                          teamId: teamId,
                          teamName: teamName,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
