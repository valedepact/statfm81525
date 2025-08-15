// lib/screens/match_management_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:statform/screens/match_screen.dart'; // Re-added MatchScreen import

class MatchManagementScreen extends StatefulWidget {
  // Removed teamId from constructor as it's no longer required at initial navigation
  const MatchManagementScreen({super.key});

  @override
  State<MatchManagementScreen> createState() => _MatchManagementScreenState();
}

class _MatchManagementScreenState extends State<MatchManagementScreen> {
  String? _selectedHomeTeamId; // Re-declared
  String? _selectedAwayTeamId; // Re-declared
  // These will store the selected team documents
  DocumentSnapshot? _selectedHomeTeamDoc;
  DocumentSnapshot? _selectedAwayTeamDoc;

  // To store the fetched prepared match lineups for home and away teams
  List<String> _homeTeamPreparedLineup = []; // Changed type to List<String>
  List<String> _awayTeamPreparedLineup = []; // Changed type to List<String>

  bool _isLoading = false;
  final TextEditingController _matchDurationController = TextEditingController(); // New controller

  @override
  void initState() {
    super.initState();
    // Initial fetch if any team is pre-selected (though not currently the case)
    _fetchPreparedLineups();
  }

  @override
  void dispose() {
    _matchDurationController.dispose(); // Dispose the controller
    super.dispose();
  }

  // Function to fetch prepared lineups for both home and away teams
  Future<void> _fetchPreparedLineups() async {
    debugPrint('Fetching prepared lineups...');
    setState(() {
      _isLoading = true;
      _homeTeamPreparedLineup = []; // Reset before fetching
      _awayTeamPreparedLineup = []; // Reset before fetching
    });
    try {
      // Only fetch if a team is selected; otherwise, it would be a broad query
      if (_selectedHomeTeamDoc != null) {
        final homeQuery = await FirebaseFirestore.instance
            .collection('preparedMatches')
            .where('teamId', isEqualTo: _selectedHomeTeamDoc!.id)
            .limit(1)
            .get();
        if (homeQuery.docs.isNotEmpty) {
          final List<dynamic> playerIdsDynamic = homeQuery.docs.first['playerIds'] ?? [];
          _homeTeamPreparedLineup = playerIdsDynamic.map((e) => e.toString()).toList();
        } else {
          _homeTeamPreparedLineup = []; // Ensure it's an empty list if no lineup found
        }
        debugPrint('Home Team Prepared Lineup Found: ${_homeTeamPreparedLineup.isNotEmpty}');
      }

      if (_selectedAwayTeamDoc != null) {
        final awayQuery = await FirebaseFirestore.instance
            .collection('preparedMatches')
            .where('teamId', isEqualTo: _selectedAwayTeamDoc!.id)
            .limit(1)
            .get();
        if (awayQuery.docs.isNotEmpty) {
          final List<dynamic> playerIdsDynamic = awayQuery.docs.first['playerIds'] ?? [];
          _awayTeamPreparedLineup = playerIdsDynamic.map((e) => e.toString()).toList();
        } else {
          _awayTeamPreparedLineup = []; // Ensure it's an empty list if no lineup found
        }
        debugPrint('Away Team Prepared Lineup Found: ${_awayTeamPreparedLineup.isNotEmpty}');
      }
    } catch (e) {
      debugPrint('Error fetching prepared lineups: $e');
      _showSnackBar('Error fetching prepared lineups: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // StreamBuilder listens for real-time changes in the 'teams' collection
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Matches'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('teams').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No teams found. Please create a team first.'));
          }

          final teams = snapshot.data!.docs;
          final teamNames = teams.map((doc) => doc['teamName'] as String).toList(); // Corrected to use 'teamName'

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Match Duration Input
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: TextFormField(
                    controller: _matchDurationController,
                    decoration: const InputDecoration(
                      labelText: 'Match Duration (minutes)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.timer),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter match duration';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                ),
                const Text(
                  'Select Home Team',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  value: _selectedHomeTeamDoc?['teamName'] as String?, // Corrected to use 'teamName'
                  items: teamNames.map((name) {
                    return DropdownMenuItem(
                      value: name,
                      child: Text(name),
                    );
                  }).toList(),
                  onChanged: (String? newName) async {
                    setState(() {
                      _selectedHomeTeamDoc = newName != null
                          ? teams.firstWhere((doc) => doc['teamName'] == newName) // Corrected to use 'teamName'
                          : null;
                      _selectedHomeTeamId = _selectedHomeTeamDoc?.id; // Ensure ID is set
                    });
                    await _fetchPreparedLineups(); // Fetch lineup for selected team
                  },
                ),
                // Display Prepared Lineup for Home Team
                if (_selectedHomeTeamDoc != null) // Only show if a home team is selected
                  _buildPreparedLineupDisplay(_homeTeamPreparedLineup, _selectedHomeTeamDoc!, 'home'),
                const SizedBox(height: 20),
                const Text(
                  'Select Away Team',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  value: _selectedAwayTeamDoc?['teamName'] as String?, // Corrected to use 'teamName'
                  items: teamNames.map((name) {
                    return DropdownMenuItem(
                      value: name,
                      child: Text(name),
                    );
                  }).toList(),
                  onChanged: (String? newName) async {
                    setState(() {
                      _selectedAwayTeamDoc = newName != null
                          ? teams.firstWhere((doc) => doc['teamName'] == newName) // Corrected to use 'teamName'
                          : null;
                      _selectedAwayTeamId = _selectedAwayTeamDoc?.id; // Ensure ID is set
                    });
                    await _fetchPreparedLineups(); // Fetch lineup for selected team
                  },
                ),
                // Display Prepared Lineup for Away Team
                if (_selectedAwayTeamDoc != null) // Only show if an away team is selected
                  _buildPreparedLineupDisplay(_awayTeamPreparedLineup, _selectedAwayTeamDoc!, 'away'),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    if (_selectedHomeTeamId == null || _selectedAwayTeamId == null) {
                      _showSnackBar('Please select both home and away teams.');
                      return;
                    }

                    if (_homeTeamPreparedLineup.isEmpty) {
                      _showSnackBar('Home team lineup is not prepared.');
                      return;
                    }

                    if (_awayTeamPreparedLineup.isEmpty) {
                      _showSnackBar('Away team lineup is not prepared.');
                      return;
                    }

                    final String matchDuration = _matchDurationController.text.trim(); // Get duration
                    if (matchDuration.isEmpty) {
                      _showSnackBar('Please enter match duration.');
                      return;
                    }
                    if (int.tryParse(matchDuration) == null) {
                      _showSnackBar('Please enter a valid number for match duration.');
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MatchScreen(
                          homeTeamId: _selectedHomeTeamId!,
                          awayTeamId: _selectedAwayTeamId!,
                          homePlayerIds: _homeTeamPreparedLineup,
                          awayPlayerIds: _awayTeamPreparedLineup,
                          matchDuration: int.parse(matchDuration),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15.0),
                  ),
                  child: const Text(
                    'Start Match',
                    style: TextStyle(fontSize: 18.0),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper widget to build the prepared lineup display
  Widget _buildPreparedLineupDisplay(List<String> preparedPlayerIds, DocumentSnapshot teamDoc, String teamType) {
    if (preparedPlayerIds.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 10.0),
        child: Text('No prepared lineup for ${teamDoc['teamName'] ?? 'this team'}. Please create one from Manager Dashboard.'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(
          'Lineup for ${teamDoc['teamName'] ?? 'Team'}:',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        // Stream the actual player documents to display their names and details
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('teams')
              .doc(teamDoc.id)
              .collection('members')
              .where(FieldPath.documentId, whereIn: preparedPlayerIds)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Loading lineup...');
            }
            if (snapshot.hasError) {
              return Text('Error loading lineup: ${snapshot.error}');
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Text('No players in this lineup.');
            }

            final lineupPlayers = snapshot.data!.docs;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: lineupPlayers.map((playerDoc) {
                final playerData = playerDoc.data() as Map<String, dynamic>;
                final playerName = playerData['name'] ?? 'N/A';
                final shirtNumber = playerData['shirtNumber'] ?? 'N/A';
                final position = playerData['position'] ?? 'N/A';
                return Text('- $playerName (Shirt: $shirtNumber, Pos: $position)');
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 10),
        // TODO: Add an 'Edit Lineup' button here that navigates to MatchManagementScreen
        // with the specific teamId and pre-loads the selected players from preparedLineup
      ],
    );
  }
}
