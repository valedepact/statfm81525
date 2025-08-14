// lib/models/player_stats_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerStats {
  String id;
  String name;
  int number; // The field name for shirt number is 'number'
  int goalsScored;
  int goalsMissed;
  int assists;
  int gkSaves;
  int blocks;
  int turnovers;

  PlayerStats({
    required this.id,
    required this.name,
    required this.number,
    this.goalsScored = 0,
    this.goalsMissed = 0,
    this.assists = 0,
    this.gkSaves = 0,
    this.blocks = 0,
    this.turnovers = 0,
  });

  // Method to convert PlayerStats object to a Firestore-compatible map
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'number': number,
      'goalsScored': goalsScored,
      'goalsMissed': goalsMissed,
      'assists': assists,
      'gkSaves': gkSaves,
      'blocks': blocks,
      'turnovers': turnovers,
    };
  }

  // Factory constructor to create a PlayerStats object from a Firestore document
  factory PlayerStats.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PlayerStats(
      id: doc.id,
      name: data['name'] ?? 'No Name',
      number: data['number'] ?? 0,
      goalsScored: data['goalsScored'] ?? 0,
      goalsMissed: data['goalsMissed'] ?? 0,
      assists: data['assists'] ?? 0,
      gkSaves: data['gkSaves'] ?? 0,
      blocks: data['blocks'] ?? 0,
      turnovers: data['turnovers'] ?? 0,
    );
  }
}
