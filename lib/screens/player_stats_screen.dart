// lib/screens/player_stats_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:statform/screens/player_profile_screen.dart';

class PlayerStatsScreen extends StatelessWidget {
  final String teamId;
  final String? playerId; // Make playerId optional

  const PlayerStatsScreen({
    super.key,
    required this.teamId,
    this.playerId, // Make playerId optional
  });

  @override
  Widget build(BuildContext context) {
    // StreamBuilder listens for real-time changes in the 'members' subcollection
    return StreamBuilder<QuerySnapshot>(
      stream: playerId == null
          ? FirebaseFirestore.instance
              .collection('teams')
              .doc(teamId)
              .collection('members')
              .snapshots()
          : FirebaseFirestore.instance
              .collection('teams')
              .doc(teamId)
              .collection('members')
              .where(FieldPath.documentId, isEqualTo: playerId)
              .snapshots(),
      builder: (context, snapshot) {
        // Show a loading indicator while fetching data
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Player Stats'), centerTitle: true),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // Handle errors
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Player Stats'), centerTitle: true),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        // Handle the case where no players exist
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Player Stats'), centerTitle: true),
            body: const Center(child: Text('No players on this team yet.')),
          );
        }

        final players = snapshot.data!.docs;

        if (playerId != null && players.isNotEmpty) {
          // Display single player stats
          final playerData = players.first.data() as Map<String, dynamic>;
          final playerName = playerData['name'] ?? 'No Name';
          final shirtNumber = playerData['shirtNumber'] ?? 'N/A';
          final position = playerData['position'] ?? 'N/A';
          final phoneNumber = playerData['phoneNumber'] ?? 'N/A';

          return Scaffold(
            appBar: AppBar(
              title: Text('$playerName Stats'),
              centerTitle: true,
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Name: $playerName', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Shirt Number: $shirtNumber', style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('Position: $position', style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('Phone: $phoneNumber', style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 20),
                  const Text('Performance Data (TODO)', style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic)),
                  // TODO: Display detailed performance data for the player
                ],
              ),
            ),
          );
        } else {
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
                    subtitle: Text(playerData['phoneNumber'] ?? 'No Phone'), // Changed to phoneNumber
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
        }
      },
    );
  }
}
