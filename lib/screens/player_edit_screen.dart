import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Import for Hive

class PlayerEditScreen extends StatefulWidget {
  final String teamId;
  final String playerId;

  const PlayerEditScreen({super.key, required this.teamId, required this.playerId});

  @override
  State<PlayerEditScreen> createState() => _PlayerEditScreenState();
}

class _PlayerEditScreenState extends State<PlayerEditScreen> {
  final TextEditingController _playerNameController = TextEditingController();
  final TextEditingController _playerPhoneNumberController = TextEditingController();
  final TextEditingController _playerShirtNumberController = TextEditingController();
  String? _selectedPosition;
  bool _isLoading = false;

  final List<String> _positions = const [
    'P', 'C', 'RH', 'LH', 'RW', 'LW', 'GK'
  ];

  @override
  void initState() {
    super.initState();
    _loadPlayerData();
  }

  Future<void> _loadPlayerData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final playerDoc = await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .collection('members')
          .doc(widget.playerId)
          .get();

      if (playerDoc.exists) {
        final playerData = playerDoc.data() as Map<String, dynamic>;
        _playerNameController.text = playerData['name'] ?? '';
        _playerPhoneNumberController.text = playerData['phoneNumber'] ?? '';
        _playerShirtNumberController.text = playerData['shirtNumber']?.toString() ?? '';
        _selectedPosition = playerData['position'];
      }
    } catch (e) {
      _showSnackBar('Error loading player data: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updatePlayer() async {
    if (_playerNameController.text.isEmpty ||
        _playerPhoneNumberController.text.isEmpty ||
        _playerShirtNumberController.text.isEmpty ||
        _selectedPosition == null) {
      _showSnackBar('Please fill in all fields.', isError: true);
      return;
    }

    final int? shirtNumber = int.tryParse(_playerShirtNumberController.text.trim());
    if (shirtNumber == null) {
      _showSnackBar('Please enter a valid number for shirt number.', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .collection('members')
          .doc(widget.playerId)
          .update({
        'name': _playerNameController.text.trim(),
        'phoneNumber': _playerPhoneNumberController.text.trim(),
        'shirtNumber': shirtNumber,
        'position': _selectedPosition,
      });

      // Update in Hive for offline access
      final membersBox = Hive.box('members');
      await membersBox.put(widget.playerId, {
        'name': _playerNameController.text.trim(),
        'phoneNumber': _playerPhoneNumberController.text.trim(),
        'shirtNumber': shirtNumber,
        'position': _selectedPosition,
        'teamId': widget.teamId, // Ensure teamId is still present
        // Note: joinedAt and imageUrl are not updated here as they are not editable on this screen
      });

      _showSnackBar('Player updated successfully!');
      if (mounted) {
        Navigator.pop(context); // Go back to the previous screen
      }
    } catch (e) {
      _showSnackBar('Error updating player: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
  void dispose() {
    _playerNameController.dispose();
    _playerPhoneNumberController.dispose();
    _playerShirtNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Player'), centerTitle: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Player'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _playerNameController,
              decoration: const InputDecoration(
                labelText: 'Player Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _playerPhoneNumberController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _playerShirtNumberController,
              decoration: const InputDecoration(
                labelText: 'Shirt Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedPosition,
              hint: const Text('Select Position'),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: _positions.map((String position) {
                return DropdownMenuItem<String>(
                  value: position,
                  child: Text(position),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedPosition = newValue;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a position';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _updatePlayer,
              icon: const Icon(Icons.save),
              label: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
