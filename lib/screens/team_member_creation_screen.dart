// team_member_creation_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; // Added import for image_picker
import 'dart:io'; // Added import for File
import 'package:firebase_storage/firebase_storage.dart'; // Added import for Firebase Storage

class TeamMemberCreationScreen extends StatefulWidget {
  final String teamId;

  const TeamMemberCreationScreen({super.key, required this.teamId});

  @override
  State<TeamMemberCreationScreen> createState() => _TeamMemberCreationScreenState();
}

class _TeamMemberCreationScreenState extends State<TeamMemberCreationScreen> {
  final TextEditingController _memberNameController = TextEditingController();
  final TextEditingController _memberEmailController = TextEditingController();
  final TextEditingController _shirtNumberController = TextEditingController(); // New controller for shirt number
  String? _selectedPosition; // To hold the selected position
  File? _pickedImage; // To store the selected image file

  final List<String> _positions = const [
    'P', 'C', 'RH', 'LH', 'RW', 'LW', 'GK'
  ];

  bool _isLoading = false;

  @override
  void dispose() {
    _memberNameController.dispose();
    _memberEmailController.dispose();
    _shirtNumberController.dispose(); // Dispose the new controller
    super.dispose();
  }

  // Function to pick an image from the gallery or camera
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery); // Or ImageSource.camera

    if (image != null) {
      setState(() {
        _pickedImage = File(image.path);
      });
    }
  }

  // Function to add the new member to Firestore.
  void _addMember() async {
    if (_memberNameController.text.isEmpty ||
        _memberEmailController.text.isEmpty ||
        _shirtNumberController.text.isEmpty || // Validate shirt number
        _selectedPosition == null) { // Validate position
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
      String? imageUrl;
      if (_pickedImage != null) {
        // Create a unique file name for the image in Firebase Storage
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_pickedImage!.path.split('/').last}';
        final destination = 'team_images/${widget.teamId}/$fileName';

        // Upload the image to Firebase Storage
        final ref = FirebaseStorage.instance.ref(destination);
        final uploadTask = ref.putFile(_pickedImage!);
        final snapshot = await uploadTask.whenComplete(() {});
        imageUrl = await snapshot.ref.getDownloadURL();
      }

      // Access the sub-collection 'members' under the specific team document.
      await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .collection('members')
          .add({
        'name': _memberNameController.text.trim(),
        'email': _memberEmailController.text.trim(),
        'shirtNumber': shirtNumber, // Add shirt number
        'position': _selectedPosition, // Add selected position
        'joinedAt': FieldValue.serverTimestamp(),
        'imageUrl': imageUrl, // Store the image URL
      });
      _showSnackBar('Member added successfully!');
      _memberNameController.clear();
      _memberEmailController.clear();
      _shirtNumberController.clear(); // Clear shirt number field
      setState(() {
        _selectedPosition = null; // Reset selected position
        _pickedImage = null; // Clear picked image
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
              controller: _memberEmailController,
              decoration: const InputDecoration(
                labelText: 'Member Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
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
              onPressed: _pickImage, // Call the _pickImage function
              icon: const Icon(Icons.camera_alt),
              label: const Text('Select Player Picture'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                foregroundColor: Colors.black54,
              ),
            ),
            if (_pickedImage != null) // Display selected image preview
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Image.file(
                  _pickedImage!,
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                ),
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
