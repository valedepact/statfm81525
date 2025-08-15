// lib/screens/player_stats_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:statform/screens/player_profile_screen.dart';
import 'package:statform/screens/player_match_detail_screen.dart'; // Added import for PlayerMatchDetailScreen
import 'package:hive_flutter/hive_flutter.dart'; // Import for Hive
import 'package:intl/intl.dart'; // Import for date formatting

class PlayerStatsScreen extends StatefulWidget { // Changed to StatefulWidget
  final String teamId;
  final String? playerId; // Make playerId optional

  const PlayerStatsScreen({
    super.key,
    required this.teamId,
    this.playerId, // Make playerId optional
  });

  @override
  State<PlayerStatsScreen> createState() => _PlayerStatsScreenState();
}

class _PlayerStatsScreenState extends State<PlayerStatsScreen> {
  Map<String, dynamic>? _playerData; // To store single player's data
  int _matchesPlayedCount = 0;
  Map<String, int> _overallPlayerStats = {};
  List<Map<String, dynamic>> _playerMatches = []; // List of match summaries
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.playerId != null) {
      _fetchPlayerMatchData();
    }
  }

  Future<void> _fetchPlayerMatchData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final membersBox = Hive.box('members'); // For player details
      final matchRecordsBox = Hive.box('matchRecords'); // For match records

      // 1. Try to load player details from Hive first
      final hivePlayerData = membersBox.get(widget.playerId) as Map<dynamic, dynamic>?;
      if (hivePlayerData != null) {
        _playerData = hivePlayerData.cast<String, dynamic>();
      }

      // 2. Try to load match records from Hive for this player
      final List<Map<String, dynamic>> hiveMatches = [];
      for (var key in matchRecordsBox.keys) {
        final matchData = matchRecordsBox.get(key) as Map<dynamic, dynamic>?;
        if (matchData != null &&
            (matchData['homePlayerIds']?.contains(widget.playerId) == true ||
                matchData['awayPlayerIds']?.contains(widget.playerId) == true)) {
          // Only add relevant match data for this player's stats
          final playerStatsInMatch = matchData['playerStats']?[widget.playerId] as Map<dynamic, dynamic>?;
          if (playerStatsInMatch != null) {
            hiveMatches.add({
              'matchId': key.toString(),
              'homeTeamName': matchData['homeTeamName'] ?? 'N/A',
              'awayTeamName': matchData['awayTeamName'] ?? 'N/A',
              'timestamp': matchData['timestamp'],
              'playerStatsInMatch': playerStatsInMatch.cast<String, dynamic>(), // Store player-specific stats for this match
            });
          }
        }
      }

      if (hiveMatches.isNotEmpty) {
        setState(() {
          _playerMatches = hiveMatches;
          _matchesPlayedCount = hiveMatches.length;
          _calculateOverallPlayerStats(hiveMatches);
          _isLoading = false; // Display Hive data immediately
        });
        debugPrint('Loaded player matches from Hive: ${_playerMatches.length}');
      }

      // 3. Then fetch from Firestore to synchronize and get latest data
      final playerDoc = await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .collection('members')
          .doc(widget.playerId)
          .get();

      if (playerDoc.exists) {
        _playerData = playerDoc.data();
        // Update Hive player data if newer
        membersBox.put(playerDoc.id, {...
          playerDoc.data()!,
          'teamId': widget.teamId,
        });
      } else {
        debugPrint('Player not found: ${widget.playerId}');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final firestoreMatchRecordsSnapshot = await FirebaseFirestore.instance
          .collection('matchRecords')
          .where('playerStats.${widget.playerId}', isNotEqualTo: null)
          .get();

      final List<Map<String, dynamic>> firestoreMatches = [];
      for (var matchDoc in firestoreMatchRecordsSnapshot.docs) {
        final matchData = matchDoc.data();
        final playerStatsInMatch = matchData['playerStats']?[widget.playerId] as Map<String, dynamic>?;
        if (playerStatsInMatch != null) {
          firestoreMatches.add({
            'matchId': matchDoc.id,
            'homeTeamName': matchData['homeTeamName'] ?? 'N/A',
            'awayTeamName': matchData['awayTeamName'] ?? 'N/A',
            'timestamp': matchData['timestamp'],
            'playerStatsInMatch': playerStatsInMatch, // Store player-specific stats for this match
          });
          // Update Hive with latest Firestore match data
          await matchRecordsBox.put(matchDoc.id, matchData); // Save full match data to Hive
        }
      }

      if (firestoreMatches.isNotEmpty) {
        // Only update if there are changes from Firestore
        if (!listEquals(_playerMatches, firestoreMatches)) {
          setState(() {
            _playerMatches = firestoreMatches;
            _matchesPlayedCount = firestoreMatches.length;
            _calculateOverallPlayerStats(firestoreMatches);
          });
          debugPrint('Synchronized player matches from Firestore: ${_playerMatches.length}');
        }
      } else if (hiveMatches.isEmpty) {
        setState(() {
          _playerMatches = [];
          _matchesPlayedCount = 0;
          _overallPlayerStats = _createEmptyStatsMap();
        });
      }
    } catch (e) {
      debugPrint('Error fetching player match data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _calculateOverallPlayerStats(List<Map<String, dynamic>> matches) {
    _overallPlayerStats = _createEmptyStatsMap();
    for (var match in matches) {
      final playerStatsInMatch = match['playerStatsInMatch'] as Map<String, dynamic>?;
      if (playerStatsInMatch != null) {
        _overallPlayerStats.update('goals', (value) => value + (playerStatsInMatch['goals'] as int? ?? 0));
        _overallPlayerStats.update('7mGoals', (value) => value + (playerStatsInMatch['7mGoals'] as int? ?? 0));
        _overallPlayerStats.update('missedShots', (value) => value + (playerStatsInMatch['missedShots'] as int? ?? 0));
        _overallPlayerStats.update('assists', (value) => value + (playerStatsInMatch['assists'] as int? ?? 0));
        _overallPlayerStats.update('saves', (value) => value + (playerStatsInMatch['saves'] as int? ?? 0));
        _overallPlayerStats.update('penaltySaves', (value) => value + (playerStatsInMatch['penaltySaves'] as int? ?? 0));
        _overallPlayerStats.update('blocks', (value) => value + (playerStatsInMatch['blocks'] as int? ?? 0));
        _overallPlayerStats.update('steals', (value) => value + (playerStatsInMatch['steals'] as int? ?? 0));
        _overallPlayerStats.update('turnovers', (value) => value + (playerStatsInMatch['turnovers'] as int? ?? 0));
        _overallPlayerStats.update('2minPenalties', (value) => value + (playerStatsInMatch['2minPenalties'] as int? ?? 0));
        _overallPlayerStats.update('redCards', (value) => value + (playerStatsInMatch['redCards'] as int? ?? 0));
      }
    }
  }

  Map<String, int> _createEmptyStatsMap() {
    return {
      'goals': 0,
      '7mGoals': 0,
      'missedShots': 0,
      'assists': 0,
      'saves': 0,
      'penaltySaves': 0,
      'blocks': 0,
      'steals': 0,
      'turnovers': 0,
      '2minPenalties': 0,
      'redCards': 0,
    };
  }

  // Helper function to compare lists of maps
  bool listEquals(List<Map<String, dynamic>> list1, List<Map<String, dynamic>> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      // For simplicity, a basic map comparison; can be enhanced for deep comparison if needed
      if (!mapEquals(list1[i], list2[i])) return false;
    }
    return true;
  }

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
    return StreamBuilder<QuerySnapshot>( // Keep StreamBuilder for initial player list if playerId is null
      stream: widget.playerId == null
          ? FirebaseFirestore.instance
              .collection('teams')
              .doc(widget.teamId)
              .collection('members')
              .snapshots()
          : null, // No stream needed if specific player data is fetched via FutureBuilder
      builder: (context, snapshot) {
        // If we are viewing all players
        if (widget.playerId == null) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              appBar: AppBar(title: const Text('Player Stats'), centerTitle: true),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return Scaffold(
              appBar: AppBar(title: const Text('Player Stats'), centerTitle: true),
              body: Center(child: Text('Error: ${snapshot.error}')),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Scaffold(
              appBar: AppBar(title: const Text('Player Stats'), centerTitle: true),
              body: const Center(child: Text('No players on this team yet.')),
            );
          }

          final players = snapshot.data!.docs;
          return Scaffold(
            appBar: AppBar(
              title: const Text('Player Stats'),
              centerTitle: true,
            ),
            body: ListView.builder(
              itemCount: players.length,
              itemBuilder: (context, index) {
                final playerData = players[index].data() as Map<String, dynamic>;
                final playerId = players[index].id;
                final playerName = playerData['name'] ?? 'No Name';

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(playerName),
                    subtitle: Text(playerData['phoneNumber'] ?? 'No Phone'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlayerStatsScreen( // Navigate back to PlayerStatsScreen with playerId
                            teamId: widget.teamId,
                            playerId: playerId,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        } else { // If a specific playerId is provided
          if (_isLoading) {
            return Scaffold(
              appBar: AppBar(title: const Text('Player Stats'), centerTitle: true),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          if (_playerData == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Player Stats'), centerTitle: true),
              body: const Center(child: Text('Player data not found.')),
            );
          }

          final playerName = _playerData!['name'] ?? 'No Name';
          final shirtNumber = _playerData!['shirtNumber'] ?? 'N/A';
          final position = _playerData!['position'] ?? 'N/A';
          final phoneNumber = _playerData!['phoneNumber'] ?? 'N/A';

          return Scaffold(
            appBar: AppBar(
              title: Text('$playerName Stats'),
              centerTitle: true,
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Name: $playerName', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Shirt Number: $shirtNumber', style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('Position: $position', style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('Phone: $phoneNumber', style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 20),
                  Text('Total Matches Played: $_matchesPlayedCount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Text('Overall Stats:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ..._overallPlayerStats.entries.map((entry) => Text(
                        '${_formatStatName(entry.key)}: ${entry.value}',
                        style: const TextStyle(fontSize: 16),
                      )),
                  const SizedBox(height: 20),
                  const Text('Matches Played:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: _playerMatches.isEmpty
                        ? const Center(child: Text('No match records found for this player.'))
                        : ListView.builder(
                            itemCount: _playerMatches.length,
                            itemBuilder: (context, index) {
                              final match = _playerMatches[index];
                              final matchId = match['matchId'];
                              final homeTeam = match['homeTeamName'];
                              final awayTeam = match['awayTeamName'];
                              final timestamp = (match['timestamp'] as Timestamp?)?.toDate();
                              final formattedDate = timestamp != null
                                  ? DateFormat('MMM d, yyyy HH:mm').format(timestamp)
                                  : 'N/A';

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4.0),
                                child: ListTile(
                                  title: Text('$homeTeam vs $awayTeam'),
                                  subtitle: Text('Date: $formattedDate'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.arrow_forward_ios),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PlayerMatchDetailScreen(
                                            teamId: widget.teamId,
                                            playerId: widget.playerId!,
                                            matchId: matchId,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  String _formatStatName(String key) {
    // Helper to convert camelCase stat keys to readable names
    switch (key) {
      case '7mGoals':
        return '7m Goals';
      case 'missedShots':
        return 'Missed Shots';
      case 'penaltySaves':
        return 'Penalty Saves';
      case '2minPenalties':
        return '2-min Penalties';
      case 'redCards':
        return 'Red Cards';
      case 'steals':
        return 'Steals/Interceptions';
      default:
        return '${key[0].toUpperCase()}${key.substring(1)}';
    }
  }
}
