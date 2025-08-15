import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:statform/screens/team_management_login_screen.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Import for Hive

class TeamListScreen extends StatefulWidget { // Changed to StatefulWidget
  const TeamListScreen({super.key});

  @override
  State<TeamListScreen> createState() => _TeamListScreenState();
}

class _TeamListScreenState extends State<TeamListScreen> {
  List<Map<String, dynamic>> _teams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Try to load from Hive first
      final teamsBox = Hive.box('teams');
      final List<Map<String, dynamic>> hiveTeams = [];
      for (var key in teamsBox.keys) {
        final teamData = teamsBox.get(key) as Map<dynamic, dynamic>?; // Use dynamic for keys/values from Hive
        if (teamData != null) {
          hiveTeams.add({...
            teamData.cast<String, dynamic>(),
            'id': key.toString(), // Add the Hive key (Firestore ID) back
          });
        }
      }

      if (hiveTeams.isNotEmpty) {
        setState(() {
          _teams = hiveTeams;
          _isLoading = false; // Display Hive data immediately
        });
        debugPrint('Loaded teams from Hive: ${_teams.length}');
      }

      // 2. Then fetch from Firestore to synchronize and get latest data
      final firestoreSnapshot = await FirebaseFirestore.instance.collection('teams').get();
      final List<Map<String, dynamic>> firestoreTeams = [];
      for (var doc in firestoreSnapshot.docs) {
        final teamData = doc.data();
        firestoreTeams.add({
          ...teamData,
          'id': doc.id,
        });
        // Update Hive with latest Firestore data
        await teamsBox.put(doc.id, teamData); // Ensure consistency
      }

      if (firestoreTeams.isNotEmpty) {
        // Only update if there are changes from Firestore
        if (!listEquals(_teams, firestoreTeams)) { // Helper to compare lists
          setState(() {
            _teams = firestoreTeams;
          });
          debugPrint('Synchronized teams from Firestore: ${_teams.length}');
        }
      } else if (hiveTeams.isEmpty) {
        // If no data in Firestore and no data in Hive, still show no teams
        setState(() {
          _teams = [];
        });
      }
    } catch (e) {
      debugPrint('Error loading teams: $e');
      // If an error occurs (e.g., no internet for Firestore), keep showing Hive data
    } finally {
      setState(() {
        _isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a Team'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _teams.isEmpty
              ? const Center(child: Text('No teams created yet.'))
              : ListView.builder(
                  itemCount: _teams.length,
                  itemBuilder: (context, index) {
                    final teamData = _teams[index];
                    final teamName = teamData['teamName'] ?? 'Unnamed Team';
                    final teamId = teamData['id']; // Use 'id' field for teamId

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.group),
                        title: Text(teamName),
                        onTap: () {
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
                ),
    );
  }
}
