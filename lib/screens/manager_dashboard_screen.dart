// lib/screens/manager_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:statform/screens/team_member_creation_screen.dart';
import 'package:statform/screens/match_management_screen.dart';
import 'package:statform/screens/player_stats_screen.dart';
import 'package:statform/screens/player_edit_screen.dart'; // Added import for PlayerEditScreen

class ManagerDashboardScreen extends StatelessWidget {
  final String teamId;

  const ManagerDashboardScreen({super.key, required this.teamId});

  // A helper method to show a confirmation dialog for deleting a member
  Future<void> _confirmDeleteMember(BuildContext context, String memberId, String memberName) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button to dismiss
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Team Member'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete $memberName?'),
                const Text('This action cannot be undone.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                // Delete the member document from the Firestore subcollection
                await FirebaseFirestore.instance
                    .collection('teams')
                    .doc(teamId)
                    .collection('members')
                    .doc(memberId)
                    .delete();
                if (context.mounted) {
                  // Show a confirmation message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$memberName has been deleted.')),
                  );
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Correctly reference the public collection path
    final publicTeamsCollection = FirebaseFirestore.instance.collection('teams');

    return StreamBuilder<DocumentSnapshot>(
      // Update the stream to use the correct path
      stream: publicTeamsCollection.doc(teamId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Team Dashboard'), centerTitle: true),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Team Dashboard'), centerTitle: true),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(title: const Text('Team Dashboard'), centerTitle: true),
            body: const Center(child: Text('Team not found!')),
          );
        }

        final teamData = snapshot.data!.data() as Map<String, dynamic>;
        final teamName = teamData['teamName'] ?? 'No Name';

        return Scaffold(
          appBar: AppBar(
            title: Text('$teamName Dashboard'),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  teamName,
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Team Actions',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const Divider(),
                // Button to add new members
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TeamMemberCreationScreen(teamId: teamId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add Team Members'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 10),
                // Button to view player stats
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to a new screen to view all player stats
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayerStatsScreen(teamId: teamId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.leaderboard),
                  label: const Text('View Player Stats'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 10),
                // Button to navigate to match management
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MatchManagementScreen(), // No longer passing teamId
                      ),
                    );
                  },
                  icon: const Icon(Icons.sports_handball),
                  label: const Text('Select Players for a Match'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Current Team Members:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const Divider(),
                StreamBuilder<QuerySnapshot>(
                  stream: publicTeamsCollection
                      .doc(teamId)
                      .collection('members')
                      .snapshots(),
                  builder: (context, memberSnapshot) {
                    if (memberSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (memberSnapshot.hasError) {
                      return Center(child: Text('Error: ${memberSnapshot.error}'));
                    }
                    if (!memberSnapshot.hasData || memberSnapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No team members yet.'));
                    }

                    final members = memberSnapshot.data!.docs;
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        final memberData = members[index].data() as Map<String, dynamic>;
                        final memberId = members[index].id;
                        final memberName = memberData['name'] ?? 'No Name';
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(memberName),
                            subtitle: Text(
                                'Shirt: ${memberData['shirtNumber'] ?? 'N/A'} | Position: ${memberData['position'] ?? 'N/A'} | Phone: ${memberData['phoneNumber'] ?? 'N/A'}'),
                            trailing: SizedBox(
                              width: 120, // Adjust width as needed to fit three icons
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blueGrey),
                                    onPressed: () {
                                      // Navigate to PlayerEditScreen for this member
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PlayerEditScreen(
                                            teamId: teamId,
                                            playerId: memberId,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.show_chart, color: Colors.green),
                                    onPressed: () {
                                      // Navigate to PlayerStatsScreen for this specific player
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PlayerStatsScreen(
                                            teamId: teamId,
                                            playerId: memberId, // Pass the member ID as playerId
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _confirmDeleteMember(context, memberId, memberName),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
