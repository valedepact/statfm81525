// lib/screens/team_stats_screen.dart
import 'package:flutter/material.dart';
import 'package:statform/models/team_stats_model.dart';
import 'package:statform/widgets/team_stats_table.dart';

class TeamStatsScreen extends StatefulWidget {
  final TeamStats team;
  final String teamId; // The ID of the team is now a required parameter

  const TeamStatsScreen({
    super.key,
    required this.team,
    required this.teamId,
  });

  @override
  State<TeamStatsScreen> createState() => _TeamStatsScreenState();
}

class _TeamStatsScreenState extends State<TeamStatsScreen> {
  // A helper widget to create a consistent cell with borders and text
  Widget _buildCell({
    required Widget child,
    required Color borderColor,
    double height = 48.0,
    bool isHeader = false,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 1),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: DefaultTextStyle.merge(
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: 12.0,
        ),
        child: child,
      ),
    );
  }

  // A helper to build a tappable cell for incrementing team stats
  Widget _buildTeamTappableCell(TeamStats team, String stat, Function() onTap) {
    int value = 0;
    if (stat == 'timeouts') {
      value = team.timeouts;
    } else if (stat == 'penalties') {
      value = team.penalties;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48.0,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 1),
        ),
        alignment: Alignment.center,
        child: Text(
          value.toString(),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12.0),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Building TeamStatsScreen for team: ${widget.team.teamName}');
    const Color borderColor = Colors.black;
    const double tableVerticalSpacing = 20.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.team.teamName} Statistics'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.team.teamName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: tableVerticalSpacing),
            // The table is a separate widget to keep the code clean
            TeamStatsTable(
              players: widget.team.players,
              teamId: widget.teamId, // Pass the team ID to the table
            ),
            const SizedBox(height: tableVerticalSpacing),
            Table(
              border: TableBorder.all(color: borderColor),
              children: [
                TableRow(
                  children: [
                    _buildCell(child: const Text('Timeouts'), borderColor: borderColor, isHeader: true),
                    _buildTeamTappableCell(widget.team, 'timeouts', () {
                      setState(() {
                        widget.team.timeouts++;
                        debugPrint('${widget.team.teamName} timeouts: ${widget.team.timeouts}');
                      });
                    }),
                  ],
                ),
                TableRow(
                  children: [
                    _buildCell(child: const Text('Penalties'), borderColor: borderColor, isHeader: true),
                    _buildTeamTappableCell(widget.team, 'penalties', () {
                      setState(() {
                        widget.team.penalties++;
                        debugPrint('${widget.team.teamName} penalties: ${widget.team.penalties}');
                      });
                    }),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
