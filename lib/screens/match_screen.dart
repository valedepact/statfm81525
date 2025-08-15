// lib/screens/match_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:statform/widgets/match_player_stats_table.dart';
import 'package:uuid/uuid.dart';
import 'package:statform/widgets/match_timer_display.dart';
import 'package:statform/widgets/active_penalties_display.dart';

class MatchScreen extends StatefulWidget {
  final String homeTeamId;
  final String awayTeamId;
  final List<String> homePlayerIds;
  final List<String> awayPlayerIds;
  final int matchDuration;

  const MatchScreen({
    super.key,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homePlayerIds,
    required this.awayPlayerIds,
    required this.matchDuration,
  });

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Stat event recording
  late Map<String, List<Map<String, dynamic>>> _playerStatEvents;

  // Aggregated stats for display (updated only when events change, not on timer ticks)
  late ValueNotifier<Map<String, Map<String, int>>> _playerDisplayStatsNotifier;

  // Penalty related state that needs to be managed here for stat enabling/disabling
  Set<String> _redCardedPlayers = {}; // Set of players who have received a red card

  // Match status for enabling/disabling stat taking
  bool _isMatchActive = false; // Controls if stats can be taken

  // GlobalKey to access MatchTimerDisplay's state and its ValueNotifier
  final GlobalKey<MatchTimerDisplayState> _matchTimerDisplayKey = GlobalKey();
  // GlobalKey to access ActivePenaltiesDisplay's state and its methods
  final GlobalKey<ActivePenaltiesDisplayState> _activePenaltiesDisplayKey = GlobalKey();

  // Store all players' data for easy lookup (playerId -> playerData map)
  late Map<String, Map<String, dynamic>> _allPlayersData;

  // Variables to hold fetched team names
  String _homeTeamName = 'Loading...';
  String _awayTeamName = 'Loading...';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializePlayerStats();
    _fetchTeamNamesAndPlayers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _playerDisplayStatsNotifier.dispose();
    super.dispose();
  }

  Future<void> _fetchTeamNamesAndPlayers() async {
    try {
      final homeTeamDoc = await FirebaseFirestore.instance.collection('teams').doc(widget.homeTeamId).get();
      final awayTeamDoc = await FirebaseFirestore.instance.collection('teams').doc(widget.awayTeamId).get();

      setState(() {
        _homeTeamName = homeTeamDoc.data()?['teamName'] ?? 'Home Team';
        _awayTeamName = awayTeamDoc.data()?['teamName'] ?? 'Away Team';
      });

      _allPlayersData = {};
      final homePlayersSnapshot = await FirebaseFirestore.instance.collection('teams').doc(widget.homeTeamId).collection('members').get();
      for (var doc in homePlayersSnapshot.docs) {
        _allPlayersData[doc.id] = doc.data();
      }
      final awayPlayersSnapshot = await FirebaseFirestore.instance.collection('teams').doc(widget.awayTeamId).collection('members').get();
      for (var doc in awayPlayersSnapshot.docs) {
        _allPlayersData[doc.id] = doc.data();
      }
    } catch (e) {
      debugPrint('Error fetching team names or players: $e');
      // Handle error, e.g., show a snackbar or set default names
    }
  }

  void _initializePlayerStats() {
    _playerStatEvents = {};
    final Map<String, Map<String, int>> initialDisplayStats = {};
    final allPlayerIds = [...widget.homePlayerIds, ...widget.awayPlayerIds];
    for (var playerId in allPlayerIds) {
      _playerStatEvents[playerId] = [];
      initialDisplayStats[playerId] = _createEmptyStatsMap();
    }
    _playerDisplayStatsNotifier = ValueNotifier(initialDisplayStats);
    _redCardedPlayers = {};
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

  int _calculateCurrentStat(String playerId, String statName) {
    return _playerStatEvents[playerId]
            ?.where((event) => event['statName'] == statName)
            .fold<int>(0, (sum, event) => sum + ((event['value'] as int?) ?? 0)) ??
        0;
  }

  void _updatePlayerDisplayStats(String playerId) {
    final updatedStats = Map<String, Map<String, int>>.from(_playerDisplayStatsNotifier.value);
    updatedStats[playerId] = {
      'goals': _calculateCurrentStat(playerId, 'goals'),
      '7mGoals': _calculateCurrentStat(playerId, '7mGoals'),
      'missedShots': _calculateCurrentStat(playerId, 'missedShots'),
      'assists': _calculateCurrentStat(playerId, 'assists'),
      'saves': _calculateCurrentStat(playerId, 'saves'),
      'penaltySaves': _calculateCurrentStat(playerId, 'penaltySaves'),
      'blocks': _calculateCurrentStat(playerId, 'blocks'),
      'steals': _calculateCurrentStat(playerId, 'steals'),
      'turnovers': _calculateCurrentStat(playerId, 'turnovers'),
      '2minPenalties': _calculateCurrentStat(playerId, '2minPenalties'),
      'redCards': _calculateCurrentStat(playerId, 'redCards'),
    };
    _playerDisplayStatsNotifier.value = updatedStats;
  }

  void _updatePlayerStat(String playerId, String statName, int increment) {
    final currentMatchTime = _matchTimerDisplayKey.currentState?.currentMatchTimeNotifier.value ?? 0;

    if (!_isMatchActive) {
      _showSnackBar('Timer is not running. Cannot take stats.', isError: true);
      return;
    }
    if (currentMatchTime >= widget.matchDuration * 60) {
      _showSnackBar('Match has ended. Cannot take stats.', isError: true);
      return;
    }
    if (_redCardedPlayers.contains(playerId)) {
      _showSnackBar('Player has a red card and cannot take more stats.', isError: true);
      return;
    }

    _playerStatEvents[playerId]!.add({
      'statName': statName,
      'value': increment,
      'timestamp': currentMatchTime,
    });

    _updatePlayerDisplayStats(playerId);

    if (statName == '2minPenalties' && increment > 0) {
      _activePenaltiesDisplayKey.currentState?.start2MinPenalty(playerId);

      final int cumulative2MinPenalties = _calculateCurrentStat(playerId, '2minPenalties');
      if (cumulative2MinPenalties >= 3) {
        if (!_redCardedPlayers.contains(playerId)) {
          setState(() {
            _redCardedPlayers.add(playerId);
          });
          _showSnackBar('Player has received a Red Card due to 3 2-minute penalties!', isError: true);
          _playerStatEvents[playerId]!.add({
            'statName': 'redCards',
            'value': 1,
            'timestamp': currentMatchTime,
          });
          _updatePlayerDisplayStats(playerId);
        }
      }
    }
  }

  Future<void> _saveMatchStats() async {
    final String matchId = const Uuid().v4();

    final Map<String, Map<String, dynamic>> finalPlayerStats = {};
    for (var playerId in [...widget.homePlayerIds, ...widget.awayPlayerIds]) {
      finalPlayerStats[playerId] = {
        'goals': _playerDisplayStatsNotifier.value[playerId]?['goals'],
        '7mGoals': _playerDisplayStatsNotifier.value[playerId]?['7mGoals'],
        'missedShots': _playerDisplayStatsNotifier.value[playerId]?['missedShots'],
        'assists': _playerDisplayStatsNotifier.value[playerId]?['assists'],
        'saves': _playerDisplayStatsNotifier.value[playerId]?['saves'],
        'penaltySaves': _playerDisplayStatsNotifier.value[playerId]?['penaltySaves'],
        'blocks': _calculateCurrentStat(playerId, 'blocks'),
        'steals': _calculateCurrentStat(playerId, 'steals'),
        'turnovers': _calculateCurrentStat(playerId, 'turnovers'),
        '2minPenalties': _calculateCurrentStat(playerId, '2minPenalties'),
        'redCards': _calculateCurrentStat(playerId, 'redCards'),
        'statEvents': _playerStatEvents[playerId],
      };
    }

    try {
      await FirebaseFirestore.instance.collection('matchRecords').doc(matchId).set({
        'homeTeamId': widget.homeTeamId,
        'awayTeamId': widget.awayTeamId,
        'homeTeamName': _homeTeamName,
        'awayTeamName': _awayTeamName,
        'timestamp': FieldValue.serverTimestamp(),
        'duration': widget.matchDuration,
        'playerStats': finalPlayerStats,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Match stats saved successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Error saving match stats: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving match stats: ${e.toString()}')),
        );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Match in Progress'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: _homeTeamName),
            Tab(text: _awayTeamName),
          ],
        ),
      ),
      body: Center( // Wrap Column with Center to force full width and centering
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            MatchTimerDisplay(
              key: _matchTimerDisplayKey,
              totalMatchDurationMinutes: widget.matchDuration,
              onTimerRunningStatusChanged: (isRunning) {
                setState(() {
                  _isMatchActive = isRunning;
                });
              },
            ),
            ActivePenaltiesDisplay(
              key: _activePenaltiesDisplayKey,
              allPlayersData: _allPlayersData,
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  MatchPlayerStatsTable(
                    teamId: widget.homeTeamId,
                    playerIds: widget.homePlayerIds,
                    teamType: 'Home',
                    teamName: _homeTeamName,
                    playerMatchStatsNotifier: _playerDisplayStatsNotifier,
                    onStatUpdated: _updatePlayerStat,
                    redCardedPlayerIds: _redCardedPlayers,
                  ),
                  MatchPlayerStatsTable(
                    teamId: widget.awayTeamId,
                    playerIds: widget.awayPlayerIds,
                    teamType: 'Away',
                    teamName: _awayTeamName,
                    playerMatchStatsNotifier: _playerDisplayStatsNotifier,
                    onStatUpdated: _updatePlayerStat,
                    redCardedPlayerIds: _redCardedPlayers,
                  ),
                ],
              ),
            ),
            FloatingActionButton.extended(
              onPressed: () => _saveMatchStats(),
              label: const Text('End Match & Save Stats'),
              icon: const Icon(Icons.save),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
