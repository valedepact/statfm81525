// lib/models/match.dart
import 'package:statform/models/team_stats_model.dart';

class Match {
  final TeamStats homeTeam;
  final TeamStats awayTeam;

  Match({
    required this.homeTeam,
    required this.awayTeam,
  });
}
