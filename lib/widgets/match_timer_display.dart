import 'package:flutter/material.dart';
import 'dart:async';

class MatchTimerDisplay extends StatefulWidget {
  final int totalMatchDurationMinutes;
  final Function(bool isRunning) onTimerRunningStatusChanged; // Removed currentMatchTime

  const MatchTimerDisplay({
    super.key,
    required this.totalMatchDurationMinutes,
    required this.onTimerRunningStatusChanged,
  });

  @override
  State<MatchTimerDisplay> createState() => MatchTimerDisplayState(); // Public state class
}

class MatchTimerDisplayState extends State<MatchTimerDisplay> {
  Timer? _matchTimer;
  // Removed _currentMatchTime; now managed by _currentMatchTimeNotifier
  bool _isRunning = false;
  bool _isPausedByTimeout = false;
  int _currentHalf = 1;
  late int _halfDurationSeconds;

  // Expose current match time via ValueNotifier for external access without rebuilds
  late ValueNotifier<int> currentMatchTimeNotifier; // New ValueNotifier

  @override
  void initState() {
    super.initState();
    _halfDurationSeconds = (widget.totalMatchDurationMinutes * 60) ~/ 2;
    currentMatchTimeNotifier = ValueNotifier(0); // Initialize notifier with 0
  }

  @override
  void dispose() {
    _matchTimer?.cancel();
    currentMatchTimeNotifier.dispose(); // Dispose the ValueNotifier
    super.dispose();
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  String _getHalfDisplayTime(int half) {
    final currentMatchTime = currentMatchTimeNotifier.value; // Use notifier's value
    if (half == 1) {
      return _formatTime(currentMatchTime <= _halfDurationSeconds ? currentMatchTime : _halfDurationSeconds);
    } else {
      return _formatTime(currentMatchTime > _halfDurationSeconds ? (currentMatchTime - _halfDurationSeconds) : 0);
    }
  }

  void _startMatchTimer() {
    if (_isRunning) return;
    if (currentMatchTimeNotifier.value >= widget.totalMatchDurationMinutes * 60) return; // Use notifier's value

    setState(() {
      _isRunning = true;
      _isPausedByTimeout = false;
    });
    widget.onTimerRunningStatusChanged(true); // Notify parent of running status change

    _matchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // No setState here, directly update the ValueNotifier's value
      final newTime = currentMatchTimeNotifier.value + 1;
      currentMatchTimeNotifier.value = newTime; // Update the notifier

      // Check for half-time and match end using the new time
      if (_currentHalf == 1 && newTime >= _halfDurationSeconds) {
        setState(() {
          _currentHalf = 2; // Update local state for half
        });
      }
      if (newTime >= widget.totalMatchDurationMinutes * 60) {
        timer.cancel();
        setState(() {
          _isRunning = false;
        });
        widget.onTimerRunningStatusChanged(false); // Notify parent
        _showSnackBar('Match ended!', isError: false);
      }
    });
  }

  void _pauseMatchTimer() {
    if (!_isRunning) return;

    setState(() {
      _isRunning = false;
      _isPausedByTimeout = true;
    });
    _matchTimer?.cancel();
    widget.onTimerRunningStatusChanged(false); // Notify parent
  }

  void _resumeMatchTimer() {
    if (_isRunning || !_isPausedByTimeout) return;
    _startMatchTimer();
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
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          ValueListenableBuilder<int>( // Listen to currentMatchTimeNotifier for updates
            valueListenable: currentMatchTimeNotifier,
            builder: (context, currentMatchTime, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('Total Time', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(_formatTime(currentMatchTime), style: const TextStyle(fontSize: 24)),
                    ],
                  ),
                  Column(
                    children: [
                      Text('Half ${_currentHalf}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(_getHalfDisplayTime(_currentHalf), style: const TextStyle(fontSize: 24)),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _isRunning ? null : _startMatchTimer,
                child: const Text('Start Match'),
              ),
              ElevatedButton(
                onPressed: _isRunning ? _pauseMatchTimer : null,
                child: const Text('Timeout'),
              ),
              ElevatedButton(
                onPressed: _isPausedByTimeout ? _resumeMatchTimer : null,
                child: const Text('Resume'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
