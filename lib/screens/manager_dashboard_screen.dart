// lib/screens/manager_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:statform/screens/team_member_creation_screen.dart';
import 'package:statform/screens/match_management_screen.dart';
import 'package:statform/screens/player_stats_screen.dart';
import 'package:statform/screens/player_edit_screen.dart';
import 'package:statform/screens/match_history_screen.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Import for Hive

class ManagerDashboardScreen extends StatefulWidget { // Changed to StatefulWidget
  final String teamId;

  const ManagerDashboardScreen({super.key, required this.teamId});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  String _teamName = 'Loading...';
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeamAndMembers();
  }

  Future<void> _loadTeamAndMembers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final teamsBox = Hive.box('teams');
      final membersBox = Hive.box('members');

      // 1. Try to load team details from Hive first
      final hiveTeamData = teamsBox.get(widget.teamId) as Map<dynamic, dynamic>?;
      if (hiveTeamData != null) {
        _teamName = hiveTeamData['teamName'] ?? 'Unnamed Team';
      }

      // 2. Try to load members from Hive first for this team
      final List<Map<String, dynamic>> hiveMembers = [];
      for (var key in membersBox.keys) {
        final memberData = membersBox.get(key) as Map<dynamic, dynamic>?;
        if (memberData != null && memberData['teamId'] == widget.teamId) {
          hiveMembers.add({...
            memberData.cast<String, dynamic>(),
            'id': key.toString(), // Add the Hive key (Firestore ID) back
          });
        }
      }

      if (hiveMembers.isNotEmpty) {
        setState(() {
          _members = hiveMembers;
          _isLoading = false; // Display Hive data immediately
        });
        debugPrint('Loaded members from Hive: ${_members.length}');
      }

      // 3. Then fetch from Firestore to synchronize and get latest data
      final firestoreTeamDoc = await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .get();
      final firestoreTeamData = firestoreTeamDoc.data();

      if (firestoreTeamData != null) {
        setState(() {
          _teamName = firestoreTeamData['teamName'] ?? 'Unnamed Team';
          // Update Hive team data if newer
          teamsBox.put(widget.teamId, firestoreTeamData);
        });
      }

      final firestoreMembersSnapshot = await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .collection('members')
          .get();

      final List<Map<String, dynamic>> firestoreMembers = [];
      for (var doc in firestoreMembersSnapshot.docs) {
        final memberData = doc.data();
        firestoreMembers.add({
          ...memberData,
          'id': doc.id,
        });
        // Update Hive with latest Firestore data for members
        await membersBox.put(doc.id, {...
          memberData,
          'teamId': widget.teamId,
        });
      }

      if (firestoreMembers.isNotEmpty) {
        // Only update if there are changes from Firestore
        if (!listEquals(_members, firestoreMembers)) {
          setState(() {
            _members = firestoreMembers;
          });
          debugPrint('Synchronized members from Firestore: ${_members.length}');
        }
      } else if (hiveMembers.isEmpty) {
        // If no data in Firestore and no data in Hive, still show no members
        setState(() {
          _members = [];
        });
      }
    } catch (e) {
      debugPrint('Error loading team or members: $e');
      // If an error occurs (e.g., no internet for Firestore), keep showing Hive data
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper function to compare lists of maps (simple comparison for now)
  bool listEquals(List<Map<String, dynamic>> list1, List<Map<String, dynamic>> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (!mapEquals(list1[i], list2[i])) return false;
    }
    return true;
  }

  // Helper function to compare maps
  bool mapEquals(Map<String, dynamic> map1, Map<String, dynamic> map2) {
    if (map1.length != map2.length) return false;
    for (var key in map1.keys) {
      if (!map2.containsKey(key) || map1[key] != map2[key]) {
        return false;
      }
    }
    return true;
  }

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
                    .doc(widget.teamId)
                    .collection('members')
                    .doc(memberId)
                    .delete();

                // Also delete from Hive for offline consistency
                final membersBox = Hive.box('members');
                await membersBox.delete(memberId);

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
      stream: publicTeamsCollection.doc(widget.teamId).snapshots(),
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
                        builder: (context) => TeamMemberCreationScreen(teamId: widget.teamId),
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
                        builder: (context) => PlayerStatsScreen(teamId: widget.teamId),
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
                const SizedBox(height: 16),
                // Button to view all matches for this team
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to a screen to view all matches played by this team
                    debugPrint('View Matches button pressed for team: ${widget.teamId}');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MatchHistoryScreen(teamId: widget.teamId), // Pass teamId to filter matches
                      ),
                    );
                  },
                  icon: const Icon(Icons.history),
                  label: const Text('View Match History'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50), // Full width button
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MatchManagementScreen(),
                      ),
                    );
                  },
                  child: const Text('Select Teams for a Match'),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Current Team Members:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const Divider(),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _members.isEmpty
                        ? const Center(child: Text('No team members yet.'))
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _members.length,
                            itemBuilder: (context, index) {
                              final memberData = _members[index];
                              final memberId = memberData['id'];
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
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => PlayerEditScreen(
                                                  teamId: widget.teamId,
                                                  playerId: memberId,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.show_chart, color: Colors.green),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => PlayerStatsScreen(
                                                  teamId: widget.teamId,
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
                          ),
              ],
            ),
          ),
        );
      },
    );
  }
}
