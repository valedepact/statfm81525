// lib/services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:statform/models/team_stats_model.dart';
import 'package:statform/models/player_stats_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a new player to a team
  Future<void> addPlayer(String teamId, PlayerStats player) async {
    await _firestore
        .collection('teams')
        .doc(teamId)
        .collection('members')
        .doc(player.id)
        .set(player.toFirestore());
  }

  // Fetch a single team by ID
  Future<TeamStats?> getTeam(String teamId) async {
    final doc = await _firestore.collection('teams').doc(teamId).get();
    if (doc.exists) {
      return TeamStats.fromFirestore(doc);
    }
    return null;
  }
}
