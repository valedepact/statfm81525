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
  final TextEditingController _memberEmailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _memberNameController.dispose();
    _memberEmailController.dispose();
    super.dispose();
  }

  // Function to add the new member to Firestore.
  void _addMember() async {
    if (_memberNameController.text.isEmpty || _memberEmailController.text.isEmpty) {
      _showSnackBar('Please fill in both fields.', isError: true);
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
        'email': _memberEmailController.text.trim(),
        'joinedAt': FieldValue.serverTimestamp(),
      });
      _showSnackBar('Member added successfully!');
      _memberNameController.clear();
      _memberEmailController.clear();
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
              controller: _memberEmailController,
              decoration: const InputDecoration(
                labelText: 'Member Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
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
                        subtitle: Text(memberData['email'] ?? 'No Email'),
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
