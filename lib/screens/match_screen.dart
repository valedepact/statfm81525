// lib/screens/match_screen.dart
import 'package:flutter/material.dart';
import 'package:statform/models/match.dart';
import 'package:statform/screens/home_team.dart';
import 'package:statform/screens/away_team.dart';

class MatchScreen extends StatelessWidget {
  final Match match;
  final String homeTeamId;
  final String awayTeamId;

  const MatchScreen({
    super.key,
    required this.match,
    required this.homeTeamId,
    required this.awayTeamId,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Match Stats'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Home Team'),
              Tab(text: 'Away Team'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Pass the homeTeamId to the HomeTeam widget
            HomeTeam(team: match.homeTeam, teamId: homeTeamId),
            // Pass the awayTeamId to the AwayTeam widget
            AwayTeam(team: match.awayTeam, teamId: awayTeamId),
          ],
        ),
      ),
    );
  }
}
