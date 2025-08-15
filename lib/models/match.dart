// lib/models/match.dart
import 'package:statform/models/team_stats_model.dart';

class Match {
  final String id; // Added match ID
  final String homeTeamId;
  final String awayTeamId;
  final int duration; // New field for match duration
  // You might want to add other match details here, e.g., opponent, date, etc.

  Match({
    required this.id, // Required match ID
    required this.homeTeamId,
    required this.awayTeamId,
    required this.duration, // Add to constructor
  });
}
