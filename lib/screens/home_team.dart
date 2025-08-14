// lib/screens/home_team.dart
import 'package:flutter/material.dart';
import 'package:statform/models/team_stats_model.dart';
import 'package:statform/widgets/team_stats_table.dart';

class HomeTeam extends StatelessWidget {
  final TeamStats team;
  final String teamId;

  const HomeTeam({
    super.key,
    required this.team,
    required this.teamId,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            team.teamName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          // Pass the teamId to the TeamStatsTable widget
          TeamStatsTable(players: team.players, teamId: teamId),
          const SizedBox(height: 20),
          Table(
            border: TableBorder.all(color: Colors.black),
            children: [
              const TableRow(
                children: [
                  Center(child: Text('Timeouts')),
                  Center(child: Text('Penalties')),
                ],
              ),
              TableRow(
                children: [
                  Center(child: Text(team.timeouts.toString())),
                  Center(child: Text(team.penalties.toString())),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
