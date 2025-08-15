// team_member_creation_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeamMemberCreationScreen extends StatefulWidget {
  final String teamId;

  const TeamMemberCreationScreen({super.key, required this.teamId});

  @override
  State<TeamMemberCreationScreen> createState() => _TeamMemberCreationScreenState();
}

class _TeamMemberCreationScreenState extends State<TeamMemberCreationScreen> {
  final TextEditingController _memberNameController = TextEditingController();
  final TextEditingController _memberPhoneNumberController = TextEditingController(); // Changed from email to phone number
  final TextEditingController _shirtNumberController = TextEditingController();
  String? _selectedPosition;

  final List<String> _positions = const [
    'P', 'C', 'RH', 'LH', 'RW', 'LW', 'GK'
  ];

  bool _isLoading = false;

  @override
  void dispose() {
    _memberNameController.dispose();
    _memberPhoneNumberController.dispose(); // Dispose the new controller
    _shirtNumberController.dispose();
    super.dispose();
  }

  // Function to add the new member to Firestore.
  void _addMember() async {
    if (_memberNameController.text.isEmpty ||
        _memberPhoneNumberController.text.isEmpty || // Validate phone number
        _shirtNumberController.text.isEmpty ||
        _selectedPosition == null) {
      _showSnackBar('Please fill in all fields.', isError: true);
      return;
    }

    // Basic validation for shirt number to be an integer
    final int? shirtNumber = int.tryParse(_shirtNumberController.text.trim());
    if (shirtNumber == null) {
      _showSnackBar('Please enter a valid number for shirt number.', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Access the sub-collection 'members' under the specific team document.
      await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .collection('members')
          .add({
        'name': _memberNameController.text.trim(),
        'phoneNumber': _memberPhoneNumberController.text.trim(), // Storing phone number instead of email
        'shirtNumber': shirtNumber, // Add shirt number
        'position': _selectedPosition, // Add selected position
        'joinedAt': FieldValue.serverTimestamp(),
        'imageUrl': null, // Removed image upload logic, set to null
      });
      _showSnackBar('Member added successfully!');
      _memberNameController.clear();
      _memberPhoneNumberController.clear(); // Clear phone number field
      _shirtNumberController.clear();
      setState(() {
        _selectedPosition = null;
      });
    } catch (e) {
      _showSnackBar('Error adding member: $e', isError: true);
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Team Members'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Adding members to team ID: ${widget.teamId}',
              style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _memberNameController,
              decoration: const InputDecoration(
                labelText: 'Member Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _memberPhoneNumberController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone, // Changed keyboard type to phone
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _shirtNumberController,
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
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _addMember,
              icon: const Icon(Icons.person_add),
              label: const Text('Add Member'),
            ),
            const SizedBox(height: 30),
            const Text(
              'Current Team Members:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('teams')
                    .doc(widget.teamId)
                    .collection('members')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No team members yet.'));
                  }

                  final members = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final memberData = members[index].data() as Map<String, dynamic>;
                      return ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(memberData['name'] ?? 'No Name'),
                        subtitle: Text(
                            'Shirt: ${memberData['shirtNumber'] ?? 'N/A'} | Position: ${memberData['position'] ?? 'N/A'}'),
                        trailing: Text(memberData['email'] ?? 'No Email'),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
