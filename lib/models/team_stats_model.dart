// lib/models/team_stats_model.dart
import 'package:statform/models/player_stats_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeamStats {
  String teamName;
  int timeouts;
  int penalties;
  List<PlayerStats> players;

  TeamStats({
    required this.teamName,
    this.timeouts = 0,
    this.penalties = 0,
    List<PlayerStats>? players,
  }) : players = players ?? [];

  // Factory constructor to create a TeamStats object from a Firestore Document
  factory TeamStats.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final playerList = (data['players'] as List? ?? [])
        .map((playerData) {
      // Assuming player data is in a Map format
      return PlayerStats(
        id: playerData['id'] ?? '',
        name: playerData['name'] ?? 'No Name',
        number: playerData['number'] ?? 0,
        goalsScored: playerData['goalsScored'] ?? 0,
        goalsMissed: playerData['goalsMissed'] ?? 0,
        assists: playerData['assists'] ?? 0,
        gkSaves: playerData['gkSaves'] ?? 0,
        blocks: playerData['blocks'] ?? 0,
        turnovers: playerData['turnovers'] ?? 0,
      );
    })
        .toList();

    return TeamStats(
      teamName: data['teamName'] ?? 'No Name',
      timeouts: data['timeouts'] ?? 0,
      penalties: data['penalties'] ?? 0,
      players: playerList,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'teamName': teamName,
      'timeouts': timeouts,
      'penalties': penalties,
      'players': players.map((p) => p.toFirestore()).toList(),
    };
  }
}
