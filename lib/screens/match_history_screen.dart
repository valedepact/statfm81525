import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:statform/screens/match_summary_screen.dart'; // New screen for match details
import 'package:hive_flutter/hive_flutter.dart'; // Import for Hive

class MatchHistoryScreen extends StatefulWidget {
  final String teamId;

  const MatchHistoryScreen({super.key, required this.teamId});

  @override
  State<MatchHistoryScreen> createState() => _MatchHistoryScreenState();
}

class _MatchHistoryScreenState extends State<MatchHistoryScreen> {
  List<Map<String, dynamic>> _matches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMatchRecords();
  }

  Future<void> _loadMatchRecords() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final matchRecordsBox = Hive.box('matchRecords');
      final List<Map<String, dynamic>> hiveMatches = [];
      for (var key in matchRecordsBox.keys) {
        final matchData = matchRecordsBox.get(key) as Map<dynamic, dynamic>?;
        if (matchData != null &&
            (matchData['homeTeamId'] == widget.teamId ||
                matchData['awayTeamId'] == widget.teamId)) {
          hiveMatches.add({...
            matchData.cast<String, dynamic>(),
            'id': key.toString(),
          });
        }
      }

      if (hiveMatches.isNotEmpty) {
        setState(() {
          // Sort Hive matches by timestamp (most recent first)
          _matches = hiveMatches.toList()
            ..sort((a, b) {
              final DateTime? timeA = DateTime.tryParse(a['timestamp'] ?? '');
              final DateTime? timeB = DateTime.tryParse(b['timestamp'] ?? '');
              if (timeA == null || timeB == null) return 0; // Handle nulls gracefully
              return timeB.compareTo(timeA); // Descending order
            });
          _isLoading = false; // Display Hive data immediately
        });
        debugPrint('Loaded matches from Hive: ${_matches.length}');
      }

      final firestoreSnapshot = await FirebaseFirestore.instance
          .collection('matchRecords')
          .where('homeTeamId', isEqualTo: widget.teamId) // Assuming team can only be home team for history
          .get();

      final List<Map<String, dynamic>> firestoreMatches = [];
      for (var doc in firestoreSnapshot.docs) {
        final matchData = doc.data();
        firestoreMatches.add({
          ...matchData,
          'id': doc.id,
        });
        // Update Hive with latest Firestore data
        await matchRecordsBox.put(doc.id, {...
          matchData,
          'id': doc.id,
        });
      }

      if (firestoreMatches.isNotEmpty) {
        // Only update if there are changes from Firestore
        // Sort Firestore matches by timestamp (most recent first)
        firestoreMatches.sort((a, b) {
          final Timestamp? tsA = a['timestamp'] as Timestamp?;
          final Timestamp? tsB = b['timestamp'] as Timestamp?;
          if (tsA == null || tsB == null) return 0;
          return tsB.toDate().compareTo(tsA.toDate()); // Descending order
        });

        if (!listEquals(_matches, firestoreMatches)) {
          setState(() {
            _matches = firestoreMatches;
          });
          debugPrint('Synchronized matches from Firestore: ${_matches.length}');
        }
      } else if (hiveMatches.isEmpty) {
        setState(() {
          _matches = [];
        });
      }
    } catch (e) {
      debugPrint('Error loading match records: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Match History'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _matches.isEmpty
              ? const Center(child: Text('No matches recorded for this team.'))
              : ListView.builder(
                  itemCount: _matches.length,
                  itemBuilder: (context, index) {
                    final matchData = _matches[index];
                    final matchId = matchData['id'];
                    final homeTeamName = matchData['homeTeamName'] ?? 'N/A';
                    final awayTeamName = matchData['awayTeamName'] ?? 'N/A';
                    
                    // Handle timestamp for both Firestore Timestamp and Hive String
                    DateTime? timestamp;
                    if (matchData['timestamp'] is Timestamp) {
                      timestamp = (matchData['timestamp'] as Timestamp).toDate();
                    } else if (matchData['timestamp'] is String) {
                      timestamp = DateTime.tryParse(matchData['timestamp']);
                    }

                    final formattedDate = timestamp != null
                        ? DateFormat('MMM d, yyyy HH:mm').format(timestamp)
                        : 'N/A';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: ListTile(
                        title: Text('$homeTeamName vs $awayTeamName'),
                        subtitle: Text('Date: $formattedDate'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MatchSummaryScreen(matchId: matchId), // Navigate to MatchSummaryScreen
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
