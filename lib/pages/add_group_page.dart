import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:karma_split/utils/image_compressor.dart';

class AddGroupPage extends StatefulWidget {
  const AddGroupPage({super.key});

  @override
  State<AddGroupPage> createState() => _AddGroupPageState();
}

class _AddGroupPageState extends State<AddGroupPage> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _memberController = TextEditingController();
  final List<Map<String, dynamic>> members = [];
  final List<Map<String, dynamic>> displayMembers = [];
  File? _groupImage;
  bool _isLoading = false;

  // Get current user from Firebase Auth
  User? get _currentUser => FirebaseAuth.instance.currentUser;

  // Store creator info for backend
  Map<String, dynamic>? _creatorData;

  @override
  void initState() {
    super.initState();
    _loadCreatorData();
  }

  Future<void> _loadCreatorData() async {
    if (_currentUser != null) {
      final phone = _currentUser!.phoneNumber;
      if (phone != null) {
        final userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('phone', isEqualTo: phone)
            .limit(1)
            .get();

        if (userQuery.docs.isNotEmpty) {
          final userData = userQuery.docs.first.data();
          setState(() {
            _creatorData = {
              'username': userData['username'],
              'name': userData['name'] ?? userData['username'],
              'photoUrl': userData['photoUrl'] ?? '',
            };
          });
        }
      }
    }
  }

  Future<void> _pickImage() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Group Picture'),
        content: const Text('Select how you want to add your group picture'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final picked = await ImagePicker().pickImage(
                source: ImageSource.camera,
                imageQuality: 80,
              );
              if (picked != null) {
                setState(() => _groupImage = File(picked.path));
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.camera_alt),
                const SizedBox(width: 8),
                const Text('Camera'),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final picked = await ImagePicker().pickImage(
                source: ImageSource.gallery,
                imageQuality: 80,
              );
              if (picked != null) {
                setState(() => _groupImage = File(picked.path));
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.photo_library),
                const SizedBox(width: 8),
                const Text('Gallery'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Upload image to Cloudinary
  Future<String> _uploadImageToCloudinary(
    File imageFile,
    String groupId,
  ) async {
    try {
      // Compress the image before uploading
      final compressedFile = await compressImage(imageFile, quality: 80);

      final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
      final uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';
      final folder = dotenv.env['CLOUDINARY_FOLDER'] ?? '';

      final request = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );
      final requestFields = {
        'upload_preset': uploadPreset,
        'folder': folder,
        'public_id': '${groupId}_grouppicture',
      };

      final imageBytes = await compressedFile.readAsBytes();
      final requestMultipart = http.MultipartRequest('POST', request);
      requestMultipart.fields.addAll(requestFields);
      requestMultipart.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: 'grouppicture.jpg',
        ),
      );

      final response = await requestMultipart.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseData);
        return jsonResponse['secure_url'];
      } else {
        throw Exception('Upload failed');
      }
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  void addMember() async {
    final username = _memberController.text.trim();
    if (username.isEmpty) return;

    // Don't allow adding creator (self)
    if (_creatorData != null && username == _creatorData!['username']) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ You cannot add yourself")),
        );
      }
      return;
    }

    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ User @$username does not exist")),
        );
      }
      return;
    }

    final userDoc = query.docs.first;
    final userData = userDoc.data();

    // Check in both members and displayMembers lists
    if (members.any((m) => m['username'] == username) ||
        displayMembers.any((m) => m['username'] == username)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("⚠️ @$username already added")));
      }
      return;
    }

    setState(() {
      displayMembers.add({
        'username': username,
        'photoUrl': userData['photoUrl'] ?? '',
        'name': userData['name'] ?? username,
      });
    });
    _memberController.clear();
  }

  Future<void> createGroup() async {
    final groupName = _groupNameController.text.trim();
    if (groupName.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter group name")),
        );
      }
      return;
    }

    // Validate group picture is mandatory
    if (_groupImage == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a group picture")),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final docRef = FirebaseFirestore.instance.collection("groups").doc();

      // Upload group image to Cloudinary (mandatory now)
      String? uploadedUrl;
      uploadedUrl = await _uploadImageToCloudinary(_groupImage!, docRef.id);

      // Build final members list with creator first, then other members
      final allMembers = <Map<String, dynamic>>[];
      if (_creatorData != null) {
        allMembers.add(_creatorData!);
      }
      allMembers.addAll(displayMembers);

      // Validate at least creator + 1 member
      if (allMembers.length < 2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please add at least one member")),
          );
        }
        return;
      }

      // Create group document
      final groupData = {
        'id': docRef.id,
        'groupName': groupName,
        'groupImageUrl': uploadedUrl,
        'createdBy': _creatorData?['username'] ?? allMembers[0]['username'],
        'members': allMembers.map((m) => m['username']).toList(),
        'totalKarmaPoints': 0.0,
        'lastActivity': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'topContributor':
            _creatorData?['username'] ?? _creatorData?['name'] ?? '',
        'topContributorImageUrl': _creatorData?['photoUrl'] ?? '',
        'topContributorKarmaPoints': 0.0,
        'isActive': true,
      };

      await docRef.set(groupData);

      // Create member subcollection documents for ALL members (including creator)
      for (final member in allMembers) {
        await docRef.collection('members').doc(member['username']).set({
          'name': member['name'] ?? member['username'],
          'photoUrl': member['photoUrl'] ?? '',
          'expensesAdded': 0,
          'karmaPoints': 0.0,
          'spent': 0.0,
          'rank': 0,
          'joinedAt': FieldValue.serverTimestamp(),
        });
      }

      // Update groupsJoined for creator and all members
      await _updateGroupsJoinedForMembers(allMembers);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Group '$groupName' created!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error creating group: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateGroupsJoinedForMembers(
    List<Map<String, dynamic>> members,
  ) async {
    for (final member in members) {
      final username = member['username'];
      try {
        // Find user document by username to get the uid
        final userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: username)
            .limit(1)
            .get();

        if (userQuery.docs.isNotEmpty) {
          final userDocId = userQuery.docs.first.id;
          // Increment groupsJoined for this user
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userDocId)
              .set({
                'groupsJoined': FieldValue.increment(1),
              }, SetOptions(merge: true));
        }
      } catch (e) {
        // Skip this member if update fails, don't block group creation
        debugPrint('Failed to update groupsJoined for @$username: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Create Group'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),

              // Group Image Section
              GestureDetector(
                onTap: _pickImage,
                child: Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[200],
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _groupImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(60),
                                child: Image.file(
                                  _groupImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Icon(
                                Icons.camera_alt,
                                size: 50,
                                color: Colors.grey[400],
                              ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Group picture is mandatory',
                  style: TextStyle(color: Colors.red[600], fontSize: 12),
                ),
              ),
              const SizedBox(height: 30),

              // Group Name Section
              Text(
                'Group Name',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _groupNameController,
                decoration: InputDecoration(
                  hintText: 'Enter group name',
                  prefixIcon: Icon(Icons.group, color: Colors.grey[600]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Add Members Section
              Text(
                'Add Members',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _memberController,
                      decoration: InputDecoration(
                        hintText: 'Enter username',
                        prefixIcon: Icon(
                          Icons.person_add,
                          color: Colors.grey[600],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => addMember(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.tonal(
                    onPressed: addMember,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Creator badge (always visible)
              if (_creatorData != null) ...[
                Text(
                  'Members (${displayMembers.length + 1})', // +1 for creator
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 12),
                // Show creator badge
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.deepPurple.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage:
                            _creatorData!['photoUrl'] != null &&
                                _creatorData!['photoUrl'].isNotEmpty
                            ? NetworkImage(_creatorData!['photoUrl'])
                            : null,
                        backgroundColor: Colors.deepPurple[100],
                        child:
                            _creatorData!['photoUrl'] == null ||
                                _creatorData!['photoUrl'].isEmpty
                            ? const Icon(Icons.person, color: Colors.deepPurple)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _creatorData!['name'] ??
                                      _creatorData!['username'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'You',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '@${_creatorData!['username']}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Show added members
              if (displayMembers.isNotEmpty) ...[
                ...displayMembers.map(
                  (m) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage:
                              m['photoUrl'] != null && m['photoUrl']!.isNotEmpty
                              ? NetworkImage(m['photoUrl']!)
                              : null,
                          backgroundColor: Colors.grey[200],
                          child: m['photoUrl'] == null || m['photoUrl']!.isEmpty
                              ? Icon(Icons.person, color: Colors.grey[400])
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m['name'] ?? m['username'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '@${m['username']}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.grey[400]),
                          onPressed: () {
                            setState(() {
                              displayMembers.remove(m);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 30),

              // Create Button
              ElevatedButton(
                onPressed: _isLoading ? null : createGroup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Create Group',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
