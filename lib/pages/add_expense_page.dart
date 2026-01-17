import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:karma_split/widgets/amount_spent.dart';
import 'package:karma_split/widgets/description.dart';
import 'package:karma_split/widgets/proof_image.dart';
import 'package:karma_split/widgets/select_group.dart';
import 'package:karma_split/widgets/tag_people_card.dart';
import 'package:karma_split/utils/karma_calculator.dart';
import 'package:karma_split/utils/image_compressor.dart';

class AddExpensePage extends StatefulWidget {
  final VoidCallback? onExpenseAdded;

  const AddExpensePage({super.key, this.onExpenseAdded});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  // Controllers
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Group State
  List<String> _groups = []; // Only group names (for UI)
  Map<String, String> _groupNameToId = {}; // name -> groupId
  final Map<String, List<String>> _groupMembers =
      {}; // group name → list of members

  String? _selectedGroup; // group name
  String? _selectedGroupId; // Firestore groupId

  // Current User
  String? _currentUsername; // Current user's username

  // Tagged People
  List<String> _taggedPeople = [];

  // IMAGE
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  bool _isButtonEnabled = false;
  bool _isSubmitting = false;

  // INIT
  @override
  void initState() {
    super.initState();

    _amountController.addListener(_updateButtonState);
    _descriptionController.addListener(_updateButtonState);

    _fetchUserGroups();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Fetch Groups
  Future<bool> _isDemoUser() async {
    final user = FirebaseAuth.instance.currentUser;
    final demoPhone = dotenv.env['DEMO_PHONE_NUMBER'] ?? "1234567890";
    return user?.phoneNumber?.contains(demoPhone) ?? false;
  }

  Future<void> _fetchUserGroups() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    try {
      // Search by phone number instead of auth UID since user documents were created with phone as ID
      final phone = user.phoneNumber ?? '';
      if (phone.isEmpty) {
        return;
      }

      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        return;
      }

      final userDoc = userQuery.docs.first;
      final username = userDoc['username'];

      // Store current username for filtering group members
      setState(() {
        _currentUsername = username;
      });

      final query = await FirebaseFirestore.instance
          .collection('groups')
          .where('members', arrayContains: username)
          .get();

      final Map<String, String> nameToId = {};
      final List<String> names = [];

      for (final doc in query.docs) {
        final name = doc['groupName'] as String;
        nameToId[name] = doc.id;
        names.add(name);
      }

      setState(() {
        _groups = names;
        _groupNameToId = nameToId;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  // UI helper
  void _onGroupSelected(String groupName) async {
    setState(() {
      _selectedGroup = groupName;
      _selectedGroupId = _groupNameToId[groupName];
    });

    // Fetch group members dynamically
    await _fetchGroupMembers(groupName);

    _updateButtonState();
  }

  Future<void> _fetchGroupMembers(String groupName) async {
    if (_selectedGroupId == null) return;

    try {
      final groupDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(_selectedGroupId)
          .get();

      if (groupDoc.exists) {
        final data = groupDoc.data();
        final members = List<String>.from(data?['members'] ?? []);

        // Filter out the current user to prevent self-tagging
        final filteredMembers = members
            .where((member) => member != _currentUsername)
            .toList();

        setState(() {
          _groupMembers[groupName] = filteredMembers;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void _onTagsChanged(List<String> tagged) {
    // Validate that all tagged people exist in the selected group
    if (_selectedGroup != null && _groupMembers[_selectedGroup] != null) {
      final validMembers = _groupMembers[_selectedGroup]!;
      final validatedTags = tagged
          .where((person) => validMembers.contains(person))
          .toList();
      _taggedPeople = validatedTags;
    } else {
      _taggedPeople = tagged;
    }
    _updateButtonState();
  }

  void _updateButtonState() {
    setState(() {
      _isButtonEnabled =
          _amountController.text.trim().isNotEmpty &&
          _descriptionController.text.trim().isNotEmpty &&
          _selectedGroup != null &&
          _selectedImage != null &&
          !_isSubmitting;
    });
  }

  // IMAGE
  Future<void> _onTakePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _selectedImage = File(photo.path);
      });
      _updateButtonState();
    }
  }

  Future<void> _onChooseFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
      _updateButtonState();
    }
  }

  // IMAGE UPLOAD
  Future<String> _uploadImageToCloudinary(
    File imageFile,
    String groupId,
    String expenseId,
  ) async {
    try {
      // Compress the image before uploading
      final compressedFile = await compressImage(imageFile, quality: 80);

      // Cloudinary configuration
      final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
      final uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';
      final folder = dotenv.env['CLOUDINARY_FOLDER'] ?? '';

      // Create multipart request
      final request = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );
      final requestFields = {
        'upload_preset': uploadPreset,
        'folder': folder,
        'public_id': '${groupId}_${expenseId}_expensephoto',
      };

      final imageBytes = await compressedFile.readAsBytes();

      final requestMultipart = http.MultipartRequest('POST', request);
      requestMultipart.fields.addAll(requestFields);
      requestMultipart.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: 'expensephoto.jpg',
        ),
      );

      final response = await requestMultipart.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseData);
        final secureUrl = jsonResponse['secure_url'];

        return secureUrl;
      } else {
        final responseData = await response.stream.bytesToString();
        throw Exception(
          'Upload failed with status: ${response.statusCode}. Response: $responseData',
        );
      }
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // SUBMIT (Firebase Implementation)
  Future<void> _onSubmit() async {
    if (!_isButtonEnabled || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _isButtonEnabled = false;
    });

    try {
      // Get current user
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('User not authenticated');
      }

      // Get user document by phone
      final phone = firebaseUser.phoneNumber ?? '';
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        throw Exception('User document not found');
      }

      final userDoc = userQuery.docs.first;
      final username = userDoc['username'] as String;
      final userPhotoUrl = userDoc['photoUrl'] as String? ?? '';

      // CHECK DEMO USER
      final demoPhone = dotenv.env['DEMO_PHONE_NUMBER'] ?? "1234567890";
      if (phone == "+91$demoPhone" || phone.contains(demoPhone)) {
         throw Exception("Demo User is View Only. Action restricted.");
      }

      // CHECK DAILY EXPENSE LIMIT
      final lastExpenseDateTimestamp = userDoc['lastExpenseDate'];
      int dailyCount = (userDoc['dailyExpenseCount'] as int?) ?? 0;
      
      if (lastExpenseDateTimestamp != null) {
        final lastDate = (lastExpenseDateTimestamp as Timestamp).toDate();
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
        
        if (today.isAfter(lastDay)) {
           dailyCount = 0; // Reset for new day
        }
      }
      
      if (dailyCount >= 10) {
        throw Exception("Daily limit of 10 expenses reached.");
      }

      // Create expense document first to get expenseId
      final expenseRef = FirebaseFirestore.instance
          .collection('groups')
          .doc(_selectedGroupId)
          .collection('expenses')
          .doc(); // This creates a document with a random ID

      final expenseId = expenseRef.id;

      // Upload image if selected
      String imageUrl = '';
      if (_selectedImage != null) {
        try {
          imageUrl = await _uploadImageToCloudinary(
            _selectedImage!,
            _selectedGroupId!,
            expenseId,
          );
        } catch (e) {
          rethrow; // Re-throw to be caught by outer catch block
        }
      }

      // Calculate karma points using the split formula
      final totalAmount = double.parse(_amountController.text.trim());
      final numberOfPeople =
          _taggedPeople.length + 1; // +1 for the person who paid
      final equalShare = totalAmount / numberOfPeople;
      final netContribution = totalAmount - equalShare;
      final creatorKarmaPoints = netContribution;

      // Create expense data
      final expenseData = {
        'amount': totalAmount,
        'description': _descriptionController.text.trim(),
        'createdBy': username,
        'creatorUrl': userPhotoUrl,
        'splitWith': _taggedPeople, // Tagged people who will owe money
        'karmaPoints': creatorKarmaPoints,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'groupId': _selectedGroupId,
      };

      // Save expense to Firestore
      expenseRef.set(expenseData);

      // Update creator statistics (removed totalKarmaPoints as it will be calculated dynamically)
      // ALSO UPDATE DAILY LIMIT TRACKING
      await FirebaseFirestore.instance.collection('users').doc(userDoc.id).set({
        'expensesAdded': FieldValue.increment(1),
        'totalSpent': FieldValue.increment(totalAmount),
        'dailyExpenseCount': dailyCount + 1,
        'lastExpenseDate': FieldValue.serverTimestamp(),
        // 'totalKarmaPoints' removed - will be calculated dynamically from all groups
      }, SetOptions(merge: true));

      // Update group statistics - use total amount instead of karma points for total group karma
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(_selectedGroupId!)
          .set({
            'totalKarmaPoints': FieldValue.increment(
              totalAmount,
            ), // Changed: sum of all expenses
            'lastActivity': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      // Update member ranks in the group
      await _updateGroupMemberRanks(_selectedGroupId!);

      // Update creator member statistics
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(_selectedGroupId)
          .collection('members')
          .doc(username)
          .set({
            'karmaPoints': FieldValue.increment(creatorKarmaPoints),
            'spent': FieldValue.increment(totalAmount),
            'expensesAdded': FieldValue.increment(1),
          }, SetOptions(merge: true));

      // Update user's totalKarmaPoints in users collection (calculated from all groups)
      await _updateUserTotalKarmaPointsInCollection(username);

      // Update statistics for tagged people (they owe money, so negative karma)
      for (final taggedPerson in _taggedPeople) {
        final personKarmaPoints = -equalShare; // They owe equalShare amount

        await FirebaseFirestore.instance
            .collection('groups')
            .doc(_selectedGroupId)
            .collection('members')
            .doc(taggedPerson)
            .set({
              'karmaPoints': FieldValue.increment(personKarmaPoints),
              'spent': FieldValue.increment(0), // They didn't pay anything
            }, SetOptions(merge: true));

        // Update totalKarmaPoints in users collection for tagged people too
        await _updateUserTotalKarmaPointsInCollection(taggedPerson);
      }

      // Update top contributor information (after all member statistics are updated)
      await _updateTopContributor(_selectedGroupId!, username, userPhotoUrl);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Clear form and navigate back
      _clearForm();

      // Call the callback to navigate to Groups page if provided
      if (widget.onExpenseAdded != null) {
        widget.onExpenseAdded!();
      } else {
        // Fallback to Navigator.pop for backward compatibility
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add expense: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }

      // Re-enable button
      setState(() {
        _isSubmitting = false;
        _isButtonEnabled = true;
      });
    }
  }

  void _clearForm() {
    _amountController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedGroup = null;
      _selectedGroupId = null;
      _selectedImage = null;
      _taggedPeople = []; // Clear tagged people as well
      _isSubmitting = false;
    });
  }

  // Helper method to get filtered group members (excluding current user)
  List<String> _getFilteredGroupMembers(String groupName) {
    final members = _groupMembers[groupName] ?? [];
    if (_currentUsername == null) {
      return members;
    }
    return members.where((member) => member != _currentUsername).toList();
  }

  // TOP CONTRIBUTOR UPDATE - Now queries actual leaderboard data
  Future<void> _updateTopContributor(
    String groupId,
    String currentUserUsername,
    String currentUserPhotoUrl,
  ) async {
    try {
      // Get all members ordered by karma points (highest first)
      final membersSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .collection('members')
          .orderBy('karmaPoints', descending: true)
          .limit(1)
          .get();

      if (membersSnapshot.docs.isEmpty) {
        return;
      }

      final topMemberDoc = membersSnapshot.docs.first;
      final topMemberData = topMemberDoc.data();
      final topMemberUsername = topMemberDoc.id;
      final topMemberKarmaPoints =
          (topMemberData['karmaPoints'] as num?)?.toDouble() ?? 0.0;
      final topMemberPhotoUrl = _safeImageUrl(
        topMemberData['photoUrl'] as String?,
      );

      // Get current group data to compare
      final groupDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .get();

      if (!groupDoc.exists) {
        return;
      }

      final groupData = groupDoc.data() ?? {};
      final currentTopContributor = groupData['topContributor'] as String?;
      final currentTopContributorKarmaPoints =
          (groupData['topContributorKarmaPoints'] as num?)?.toDouble() ?? 0.0;

      // Check if we need to update the top contributor
      bool shouldUpdate = false;
      String newTopContributor = topMemberUsername;
      double newTopContributorKarmaPoints = topMemberKarmaPoints;
      String newTopContributorImageUrl = topMemberPhotoUrl;

      if (currentTopContributor == null) {
        // No current top contributor
        shouldUpdate = true;
      } else if (topMemberUsername != currentTopContributor) {
        // Different person is now the top contributor
        shouldUpdate = true;
      } else if (topMemberKarmaPoints != currentTopContributorKarmaPoints) {
        // Same person but karma points changed
        shouldUpdate = true;
      }

      if (shouldUpdate) {
        // Update top contributor information in group document
        await FirebaseFirestore.instance.collection('groups').doc(groupId).set({
          'topContributor': newTopContributor,
          'topContributorKarmaPoints': newTopContributorKarmaPoints,
          'topContributorImageUrl': newTopContributorImageUrl,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      // Don't throw error to avoid breaking the main flow
    }
  }

  // Helper method to safely handle image URLs
  String _safeImageUrl(String? url) {
    if (url != null &&
        url.trim().isNotEmpty &&
        (url.startsWith('http://') || url.startsWith('https://'))) {
      return url;
    }
    return 'https://via.placeholder.com/400x250.png?text=No+Image';
  }

  // Member's rank update
  Future<void> _updateGroupMemberRanks(String groupId) async {
    try {
      // Get all members of the group, ordered by karma points
      final membersSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .collection('members')
          .orderBy('karmaPoints', descending: true)
          .get();

      final allMembers = membersSnapshot.docs;

      // Update rank for each member
      for (int i = 0; i < allMembers.length; i++) {
        final memberDoc = allMembers[i];
        final username = memberDoc.id;
        final rank = i + 1; // Ranks start from 1

        await FirebaseFirestore.instance
            .collection('groups')
            .doc(groupId)
            .collection('members')
            .doc(username)
            .set({'rank': rank}, SetOptions(merge: true));
      }
    } catch (e) {
      // Don't throw error to avoid breaking the main flow
    }
  }

  //  UPDATE USER TOTAL KARMA POINTS IN COLLECTION
  Future<void> _updateUserTotalKarmaPointsInCollection(String username) async {
    try {
      // Calculate user's total karma points from all groups
      final totalKarmaPoints =
          await KarmaCalculator.calculateUserTotalKarmaPoints(username);

      // Find the user document by username
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        final userDoc = userQuery.docs.first;

        // Update the totalKarmaPoints field
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userDoc.id)
            .set({
              'totalKarmaPoints': totalKarmaPoints,
            }, SetOptions(merge: true));
      }
    } catch (e) {
      // Don't throw error to avoid breaking the main flow
    }
  }

  // BUILD
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
             const Text(
              "Add Expense",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
             FutureBuilder(
               future: _isDemoUser(),
               builder: (context, snapshot) {
                 if (snapshot.hasData && snapshot.data == true) {
                   return const Text(
                     "(Demo View Only)",
                     style: TextStyle(fontSize: 14, color: Colors.orange),
                   );
                 }
                 return const SizedBox.shrink();
               }
             )
          ]
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            /// SELECT GROUP (REALTIME)
            SelectGroup(
              groups: _groups,
              selectedGroup: _selectedGroup,
              onGroupSelected: _onGroupSelected,
            ),

            const SizedBox(height: 16),

            AmountSpent(controller: _amountController),

            const SizedBox(height: 16),

            Description(controller: _descriptionController),

            const SizedBox(height: 16),

            /// Tag People (dynamic based on selected group)
            TagPeopleCard(
              groupMembers:
                  _selectedGroup != null &&
                      _groupMembers[_selectedGroup] != null
                  ? _getFilteredGroupMembers(_selectedGroup!)
                  : [],
              onTagsChanged: _onTagsChanged,
              currentUsername:
                  _currentUsername, // Pass current username for validation
              initialTaggedPeople:
                  _taggedPeople, // Pass current tagged people for single source of truth
            ),

            const SizedBox(height: 16),

            ProofImage(
              onTakePhoto: _onTakePhoto,
              onChooseFromGallery: _onChooseFromGallery,
            ),

            if (_selectedImage != null) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedImage!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],

            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isButtonEnabled && !_isSubmitting ? _onSubmit : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: (_isButtonEnabled && !_isSubmitting)
                    ? const Color(0xFF6A1B9A)
                    : Colors.grey,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('Submitting...'),
                      ],
                    )
                  : Text(
                      _isButtonEnabled
                          ? 'Submit Expense'
                          : 'Complete all fields to submit',
                      style: const TextStyle(fontSize: 18),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
