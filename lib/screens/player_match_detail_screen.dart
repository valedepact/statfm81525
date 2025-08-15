import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerMatchDetailScreen extends StatefulWidget {
  final String teamId;
  final String playerId;
  final String matchId;

  const PlayerMatchDetailScreen({
    super.key,
    required this.teamId,
    required this.playerId,
    required this.matchId,
  });

  @override
  State<PlayerMatchDetailScreen> createState() => _PlayerMatchDetailScreenState();
}

class _PlayerMatchDetailScreenState extends State<PlayerMatchDetailScreen> {
  Map<String, dynamic>? _playerData;
  Map<String, dynamic>? _matchData;
  Map<String, dynamic>? _playerStatsInMatch;
  List<Map<String, dynamic>>? _statEvents; // To store raw stat events
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMatchAndPlayerDetails();
  }

  Future<void> _fetchMatchAndPlayerDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch player data
      final playerDoc = await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .collection('members')
          .doc(widget.playerId)
          .get();
      _playerData = playerDoc.data();

      // Fetch specific match data
      final matchDoc = await FirebaseFirestore.instance
          .collection('matchRecords')
          .doc(widget.matchId)
          .get();
      _matchData = matchDoc.data();

      if (_matchData != null) {
        // Extract player's stats and events from this specific match
        _playerStatsInMatch = _matchData!['playerStats']?[widget.playerId] as Map<String, dynamic>?;
        _statEvents = _playerStatsInMatch?['statEvents']?.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('Error fetching player match details: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Match Details'), centerTitle: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_playerData == null || _matchData == null || _playerStatsInMatch == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Match Details'), centerTitle: true),
        body: const Center(child: Text('Data not found for this player in this match.')),
      );
    }

    final playerName = _playerData!['name'] ?? 'N/A';
    final homeTeamName = _matchData!['homeTeamName'] ?? 'N/A';
    final awayTeamName = _matchData!['awayTeamName'] ?? 'N/A';
    final matchTimestamp = (_matchData!['timestamp'] as Timestamp?)?.toDate();
    final formattedDate = matchTimestamp != null ? '${matchTimestamp.day}/${matchTimestamp.month}/${matchTimestamp.year}' : 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: Text('$playerName in $homeTeamName vs $awayTeamName'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Match Date: $formattedDate', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            const Text('Player Stats for this Match:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ..._playerStatsInMatch!.entries.where((e) => e.key != 'statEvents').map((entry) => Text(
                  '${_formatStatName(entry.key)}: ${entry.value}',
                  style: const TextStyle(fontSize: 16),
                )),
            const SizedBox(height: 20),
            const Text('Stat Events (Timestamped):', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: _statEvents == null || _statEvents!.isEmpty
                  ? const Center(child: Text('No detailed stat events recorded.'))
                  : ListView.builder(
                      itemCount: _statEvents!.length,
                      itemBuilder: (context, index) {
                        final event = _statEvents![index];
                        final statName = _formatStatName(event['statName'] ?? 'N/A');
                        final value = event['value'] ?? 'N/A';
                        final timestamp = _formatTime(event['timestamp'] ?? 0);
                        return ListTile(
                          title: Text('$statName: $value'),
                          subtitle: Text('At: $timestamp'),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
