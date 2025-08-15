import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:statform/widgets/match_player_stats_table.dart'; // Import MatchPlayerStatsTable

class MatchSummaryScreen extends StatefulWidget {
  final String matchId;

  const MatchSummaryScreen({super.key, required this.matchId});

  @override
  State<MatchSummaryScreen> createState() => _MatchSummaryScreenState();
}

class _MatchSummaryScreenState extends State<MatchSummaryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _matchData;
  Map<String, Map<String, dynamic>> _allPlayersData = {};
  bool _isLoading = true;

  String _homeTeamName = 'Loading...';
  String _awayTeamName = 'Loading...';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchMatchDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchMatchDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final matchDoc = await FirebaseFirestore.instance.collection('matchRecords').doc(widget.matchId).get();
      _matchData = matchDoc.data();

      if (_matchData != null) {
        _homeTeamName = _matchData!['homeTeamName'] ?? 'Home Team';
        _awayTeamName = _matchData!['awayTeamName'] ?? 'Away Team';

        // Fetch player names for display based on the stored player IDs
        final homeTeamId = _matchData!['homeTeamId'];
        final awayTeamId = _matchData!['awayTeamId'];

        // Fetch all members from both teams to have their data available for the table
        final homePlayersSnapshot = await FirebaseFirestore.instance.collection('teams').doc(homeTeamId).collection('members').get();
        for (var doc in homePlayersSnapshot.docs) {
          _allPlayersData[doc.id] = doc.data();
        }
        final awayPlayersSnapshot = await FirebaseFirestore.instance.collection('teams').doc(awayTeamId).collection('members').get();
        for (var doc in awayPlayersSnapshot.docs) {
          _allPlayersData[doc.id] = doc.data();
        }
      }
    } catch (e) {
      debugPrint('Error fetching match details: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // This method will display aggregated stats from the saved record, not calculate live
  Map<String, int> _getAggregatedPlayerStats(String playerId) {
    if (_matchData == null || !_matchData!.containsKey('playerStats')) {
      return _createEmptyStatsMap();
    }
    final playerStats = _matchData!['playerStats']?[playerId] as Map<String, dynamic>?;
    if (playerStats == null) return _createEmptyStatsMap();

    return {
      'goals': playerStats['goals'] as int? ?? 0,
      '7mGoals': playerStats['7mGoals'] as int? ?? 0,
      'missedShots': playerStats['missedShots'] as int? ?? 0,
      'assists': playerStats['assists'] as int? ?? 0,
      'saves': playerStats['saves'] as int? ?? 0,
      'penaltySaves': playerStats['penaltySaves'] as int? ?? 0,
      'blocks': playerStats['blocks'] as int? ?? 0,
      'steals': playerStats['steals'] as int? ?? 0,
      'turnovers': playerStats['turnovers'] as int? ?? 0,
      '2minPenalties': playerStats['2minPenalties'] as int? ?? 0,
      'redCards': playerStats['redCards'] as int? ?? 0,
    };
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

  String _formatStatName(String key) {
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Match Summary'), centerTitle: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_matchData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Match Summary'), centerTitle: true),
        body: const Center(child: Text('Match data not found.')),
      );
    }

    final matchTimestamp = (_matchData!['timestamp'] as Timestamp?)?.toDate();
    final formattedDate = matchTimestamp != null ? DateFormat('MMM d, yyyy HH:mm').format(matchTimestamp) : 'N/A';
    final homePlayerIds = List<String>.from(_matchData!['homePlayerIds'] ?? []); // Get from saved data
    final awayPlayerIds = List<String>.from(_matchData!['awayPlayerIds'] ?? []); // Get from saved data


    // Create a dummy ValueNotifier for MatchPlayerStatsTable as it expects one
    // This notifier won't be updated live, but provides the necessary type.
    final ValueNotifier<Map<String, Map<String, int>>> dummyPlayerStatsNotifier = ValueNotifier({});

    // Populate dummyNotifier with historical stats
    final Map<String, Map<String, int>> historicalDisplayStats = {};
    for (var playerId in [...homePlayerIds, ...awayPlayerIds]) {
      historicalDisplayStats[playerId] = _getAggregatedPlayerStats(playerId);
    }
    dummyPlayerStatsNotifier.value = historicalDisplayStats;

    // Identify red-carded players from the saved data
    final Set<String> redCardedPlayers = {};
    for (var playerId in [...homePlayerIds, ...awayPlayerIds]) {
      final playerStats = _getAggregatedPlayerStats(playerId);
      if (playerStats['redCards'] != null && playerStats['redCards']! > 0) {
        redCardedPlayers.add(playerId);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Summary'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: _homeTeamName),
            Tab(text: _awayTeamName),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text('Match ID: ${widget.matchId}', style: const TextStyle(fontSize: 16)),
                Text('Date: $formattedDate', style: const TextStyle(fontSize: 16)),
                Text('Duration: ${_matchData!['duration'] ?? 'N/A'} minutes', style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Home Team Stats Table (non-interactive)
                MatchPlayerStatsTable(
                  teamId: _matchData!['homeTeamId'],
                  playerIds: homePlayerIds,
                  teamType: 'Home',
                  teamName: _homeTeamName,
                  playerMatchStatsNotifier: dummyPlayerStatsNotifier, // Pass dummy notifier
                  onStatUpdated: (playerId, statName, increment) {},
                  redCardedPlayerIds: redCardedPlayers,
                ),
                // Away Team Stats Table (non-interactive)
                MatchPlayerStatsTable(
                  teamId: _matchData!['awayTeamId'],
                  playerIds: awayPlayerIds,
                  teamType: 'Away',
                  teamName: _awayTeamName,
                  playerMatchStatsNotifier: dummyPlayerStatsNotifier, // Pass dummy notifier
                  onStatUpdated: (playerId, statName, increment) {},
                  redCardedPlayerIds: redCardedPlayers,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
