// lib/screens/player_stats_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:statform/screens/player_profile_screen.dart';

class PlayerStatsScreen extends StatelessWidget {
  final String teamId;

  const PlayerStatsScreen({
    super.key,
    required this.teamId,
  });

  @override
  Widget build(BuildContext context) {
    // StreamBuilder listens for real-time changes in the 'members' subcollection
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('teams')
          .doc(teamId)
          .collection('members')
          .snapshots(),
      builder: (context, snapshot) {
        // Show a loading indicator while fetching data
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold( // Removed const
            appBar: AppBar(title: const Text('Player Stats'), centerTitle: true),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // Handle errors
        if (snapshot.hasError) {
          return Scaffold( // Removed const
            appBar: AppBar(title: const Text('Player Stats'), centerTitle: true),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        // Handle the case where no players exist
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Scaffold( // Removed const
            appBar: AppBar(title: const Text('Player Stats'), centerTitle: true),
            body: const Center(child: Text('No players on this team yet.')),
          );
        }

        final players = snapshot.data!.docs;

        return Scaffold( // Removed const
          appBar: AppBar(
            title: const Text('Player Stats'),
            centerTitle: true,
          ),
          body: ListView.builder(
            itemCount: players.length,
            itemBuilder: (context, index) {
              final playerData = players[index].data() as Map<String, dynamic>;
              final playerId = players[index].id;
              final playerName = playerData['name'] ?? 'No Name';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(playerName),
                  subtitle: Text(playerData['email'] ?? 'No Email'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Navigate to the player profile screen with the player's ID
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayerProfileScreen(
                          teamId: teamId,
                          playerId: playerId,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}
