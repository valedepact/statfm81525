import 'package:flutter/material.dart';
import 'dart:async';

class ActivePenaltiesDisplay extends StatefulWidget {
  final Map<String, Map<String, dynamic>> allPlayersData; // For player name/shirt number lookup

  const ActivePenaltiesDisplay({
    super.key,
    required this.allPlayersData,
  });

  @override
  State<ActivePenaltiesDisplay> createState() => ActivePenaltiesDisplayState(); // Public state class
}

class ActivePenaltiesDisplayState extends State<ActivePenaltiesDisplay> {
  Map<String, Timer?> _activePenaltyTimers = {}; // Maps playerId to active 2-min penalty timer
  Map<String, int> _playerPenaltyRemainingTime = {}; // Maps playerId to remaining time in seconds

  @override
  void dispose() {
    _activePenaltyTimers.values.forEach((timer) => timer?.cancel());
    super.dispose();
  }

  void start2MinPenalty(String playerId) {
    if (_activePenaltyTimers.containsKey(playerId) && _activePenaltyTimers[playerId]!.isActive) {
      return; // Player already serving a 2-min penalty
    }

    setState(() {
      _playerPenaltyRemainingTime[playerId] = 120;
    });

    final playerName = widget.allPlayersData[playerId]?['name'] ?? 'Unknown Player';
    final shirtNumber = widget.allPlayersData[playerId]?['shirtNumber']?.toString() ?? '';

    _activePenaltyTimers[playerId] = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_playerPenaltyRemainingTime[playerId]! > 0) {
          _playerPenaltyRemainingTime[playerId] = _playerPenaltyRemainingTime[playerId]! - 1;
        } else {
          timer.cancel();
          _activePenaltyTimers.remove(playerId);
          _playerPenaltyRemainingTime.remove(playerId);
          _showSnackBar('Player $playerName (Shirt: $shirtNumber) 2-minute penalty is over!', isError: false);
        }
      });
    });
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_activePenaltyTimers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 4.0),
            child: Text('Active Penalties:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _activePenaltyTimers.keys.map((playerId) {
              final remainingTime = _playerPenaltyRemainingTime[playerId]!;
              final playerName = widget.allPlayersData[playerId]?['name'] ?? 'Unknown';
              final shirtNumber = widget.allPlayersData[playerId]?['shirtNumber']?.toString() ?? '';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Text(
                  '- $playerName (Shirt: $shirtNumber): ${_formatTime(remainingTime)} remaining',
                  style: TextStyle(
                    color: remainingTime <= 10 ? Colors.red : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
