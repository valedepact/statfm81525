import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MatchPlayerStatsTable extends StatelessWidget {
  final String teamId;
  final List<String> playerIds;
  final String teamType; // This will still be 'Home' or 'Away'
  final String teamName; // New parameter for the actual team name
  final ValueNotifier<Map<String, Map<String, int>>> playerMatchStatsNotifier; // Changed type
  final Function(String playerId, String statName, int increment) onStatUpdated;
  final Set<String> redCardedPlayerIds; // New parameter

  const MatchPlayerStatsTable({
    super.key,
    required this.teamId,
    required this.playerIds,
    required this.teamType,
    required this.teamName, // Add to constructor
    required this.playerMatchStatsNotifier, // Changed parameter name
    required this.onStatUpdated,
    required this.redCardedPlayerIds, // Add to constructor
  });

  @override
  Widget build(BuildContext context) {
    if (playerIds.isEmpty) {
      return Center(child: Text('No players selected for $teamType Team.'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('teams')
          .doc(teamId)
          .collection('members')
          .where(FieldPath.documentId, whereIn: playerIds)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No selected players found for $teamType Team.'));
        }

        final players = snapshot.data!.docs;

        return ValueListenableBuilder<Map<String, Map<String, int>>>(
          valueListenable: playerMatchStatsNotifier, // Listen to the notifier
          builder: (context, playerMatchStats, child) {
            // playerMatchStats here is the actual map from the notifier
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    // Use teamName here instead of teamType
                    '$teamName Stats (Players: ${players.length})',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal, // Allows horizontal scrolling for wide tables
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Row
                        _buildHeaderRow(),
                        // Player Rows
                        ...players.map((playerDoc) {
                          final playerData = playerDoc.data() as Map<String, dynamic>;
                          final playerId = playerDoc.id;
                          final playerName = playerData['name'] ?? 'N/A';
                          final shirtNumber = playerData['shirtNumber'] ?? 'N/A';
                          final position = playerData['position'] ?? 'N/A';

                          final bool isRedCarded = redCardedPlayerIds.contains(playerId); // Check for red card

                          return _buildPlayerRow(
                            playerId,
                            playerName,
                            shirtNumber.toString(),
                            position,
                            playerMatchStats[playerId] ?? _createEmptyStatsMap(), // Use the map from notifier
                            players, // Pass the players list here
                            isRedCarded, // Pass the red card status
                            onStatUpdated, // Pass the callback
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Helper to create an empty map of all stats initialized to 0 (for internal use)
  Map<String, int> _createEmptyStatsMap() {
    return {
      'goals': 0,
      '7mGoals': 0,
      'missedShots': 0,
      'assists': 0,
      'saves': 0,
      'penaltySaves': 0,
      'blocks': 0,
      'steals': 0,
      'turnovers': 0,
      '2minPenalties': 0,
      'redCards': 0,
    };
  }

  // Helper to build the header row
  Widget _buildHeaderRow() {
    const headerStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 8.0); // Even smaller font size
    const cellPadding = EdgeInsets.symmetric(horizontal: 2, vertical: 4); // Further adjusted padding
    final headerColor = Colors.blue.shade100;
    const borderColor = Colors.grey;

    // Define fixed widths for columns
    const double playerColWidth = 100.0; // Adjusted
    const double numberColWidth = 25.0; // Adjusted
    const double statColWidth = 55.0; // Adjusted for better fit
    const double sequentialNumColWidth = 25.0; // Adjusted

    Widget _buildHeaderCell(String text, double width) {
      return SizedBox(
        width: width,
        child: Container(
          decoration: BoxDecoration(
            color: headerColor,
            border: Border.all(color: borderColor, width: 0.5),
          ),
          padding: cellPadding,
          child: Text(text, style: headerStyle, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.visible), // Ensure single line
        ),
      );
    }

    return Row(
      children: [
        _buildHeaderCell('#', sequentialNumColWidth),
        _buildHeaderCell('Player Name', playerColWidth),
        _buildHeaderCell('Shirt #', numberColWidth),
        _buildHeaderCell('Goals', statColWidth),
        _buildHeaderCell('7m Goals', statColWidth),
        _buildHeaderCell('Missed Shots', statColWidth),
        _buildHeaderCell('Assists', statColWidth),
        _buildHeaderCell('Saves', statColWidth),
        _buildHeaderCell('Penalty Saves', statColWidth),
        _buildHeaderCell('Blocks', statColWidth),
        _buildHeaderCell('Steals', statColWidth),
        _buildHeaderCell('Turnovers', statColWidth),
        _buildHeaderCell('2min Penalties', statColWidth),
        _buildHeaderCell('Red Cards', statColWidth),
      ],
    );
  }

  // Helper to build a single player's data row
  Widget _buildPlayerRow(
      String playerId,
      String playerName,
      String shirtNumber,
      String position,
      Map<String, int> currentStats, // This is now directly the map for the player
      List<QueryDocumentSnapshot> players,
      bool isRedCarded,
      Function(String playerId, String statName, int increment) onStatUpdated, // Pass callback here
      ) {
    const cellPadding = EdgeInsets.symmetric(horizontal: 2, vertical: 4);
    const borderColor = Colors.grey;
    const dataTextStyle = TextStyle(fontSize: 8.0); // Even smaller font for data cells

    // Define fixed widths for columns, matching the header
    const double playerColWidth = 100.0;
    const double numberColWidth = 25.0;
    const double statColWidth = 55.0; // Adjusted for better fit
    const double sequentialNumColWidth = 25.0;

    Widget _buildDataCell(Widget child, double width, {bool tappable = false, String statName = ''}) {
      return SizedBox(
        width: width,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 0.5),
          ),
          padding: cellPadding,
          child: tappable
              ? GestureDetector(
            onTap: () => onStatUpdated(playerId, statName, 1),
            onLongPress: () => onStatUpdated(playerId, statName, -1),
            child: Center(child: child),
          )
              : Center(child: child),
        ),
      );
    }

    // Get the index of the current player to generate a sequential number
    final int sequentialNumber = players.indexOf(players.firstWhere((element) => element.id == playerId)) + 1;

    return Row(
      children: [
        _buildDataCell(Text(sequentialNumber.toString(), style: dataTextStyle, maxLines: 1, overflow: TextOverflow.visible), sequentialNumColWidth),
        _buildDataCell(
          Text(
            playerName,
            style: TextStyle(
              fontSize: 8.0,
              color: isRedCarded ? Colors.red : Colors.black, // Red if red-carded
              decoration: isRedCarded ? TextDecoration.lineThrough : TextDecoration.none, // Strikethrough if red-carded
            ),
            maxLines: 1,
            overflow: TextOverflow.visible,
          ),
          playerColWidth,
        ),
        _buildDataCell(Text(shirtNumber, style: dataTextStyle, maxLines: 1, overflow: TextOverflow.visible), numberColWidth),
        _buildDataCell(Text(currentStats['goals']!.toString(), style: dataTextStyle, maxLines: 1, overflow: TextOverflow.visible), statColWidth, tappable: true, statName: 'goals'),
        _buildDataCell(Text(currentStats['7mGoals']!.toString(), style: dataTextStyle, maxLines: 1, overflow: TextOverflow.visible), statColWidth, tappable: true, statName: '7mGoals'),
        _buildDataCell(Text(currentStats['missedShots']!.toString(), style: dataTextStyle, maxLines: 1, overflow: TextOverflow.visible), statColWidth, tappable: true, statName: 'missedShots'),
        _buildDataCell(Text(currentStats['assists']!.toString(), style: dataTextStyle, maxLines: 1, overflow: TextOverflow.visible), statColWidth, tappable: true, statName: 'assists'),
        // Conditional rendering for GK-specific stats
        _buildDataCell(Text(currentStats['saves']!.toString(), style: dataTextStyle, maxLines: 1, overflow: TextOverflow.visible), statColWidth, tappable: true, statName: 'saves'),
        _buildDataCell(Text(currentStats['penaltySaves']!.toString(), style: dataTextStyle, maxLines: 1, overflow: TextOverflow.visible), statColWidth, tappable: true, statName: 'penaltySaves'),
        _buildDataCell(Text(currentStats['blocks']!.toString(), style: dataTextStyle, maxLines: 1, overflow: TextOverflow.visible), statColWidth, tappable: true, statName: 'blocks'),
        _buildDataCell(Text(currentStats['steals']!.toString(), style: dataTextStyle, maxLines: 1, overflow: TextOverflow.visible), statColWidth, tappable: true, statName: 'steals'),
        _buildDataCell(Text(currentStats['turnovers']!.toString(), style: dataTextStyle, maxLines: 1, overflow: TextOverflow.visible), statColWidth, tappable: true, statName: 'turnovers'),
        _buildDataCell(Text(currentStats['2minPenalties']!.toString(), style: dataTextStyle, maxLines: 1, overflow: TextOverflow.visible), statColWidth, tappable: true, statName: '2minPenalties'),
        _buildDataCell(Text(currentStats['redCards']!.toString(), style: dataTextStyle, maxLines: 1, overflow: TextOverflow.visible), statColWidth, tappable: true, statName: 'redCards'),
      ],
    );
  }
}
