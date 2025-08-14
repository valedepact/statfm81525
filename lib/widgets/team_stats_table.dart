// lib/widgets/team_stats_table.dart
import 'package:flutter/material.dart';
import 'package:statform/models/player_stats_model.dart';
import 'package:statform/screens/player_profile_screen.dart';

class TeamStatsTable extends StatelessWidget {
  final List<PlayerStats> players;
  final String teamId;

  const TeamStatsTable({
    super.key,
    required this.players,
    required this.teamId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Table(
          columnWidths: const {
            0: FlexColumnWidth(1),
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1),
          },
          border: TableBorder.all(color: Colors.black),
          children: [
            const TableRow(
              decoration: BoxDecoration(color: Colors.grey),
              children: [
                Center(child: Text('Shirt')),
                Center(child: Text('Player')),
                Center(child: Text('Goals')),
                Center(child: Text('Assists')),
              ],
            ),
            ...players.map((player) {
              return TableRow(
                children: [
                  Center(child: Text(player.number.toString())),
                  ListTile(
                    title: Text(player.name),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlayerProfileScreen(
                            teamId: teamId,
                            playerId: player.id, // Correctly using the player's id
                          ),
                        ),
                      );
                    },
                  ),
                  Center(child: Text(player.goalsScored.toString())),
                  Center(child: Text(player.assists.toString())),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }
}
