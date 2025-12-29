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

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});

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
    _taggedPeople = tagged;
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
    print('🔍 DEBUG: Starting image upload process...');

    try {
      // Cloudinary configuration
      final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
      final uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';
      final folder = dotenv.env['CLOUDINARY_FOLDER'] ?? '';

      print(
        '🔍 DEBUG: Cloudinary config - Cloud: $cloudName, Preset: $uploadPreset, Folder: $folder',
      );
      print(
        '🔍 DEBUG: Upload details - GroupID: $groupId, ExpenseID: $expenseId',
      );
      print('🔍 DEBUG: Image file path: ${imageFile.path}');

      // Create multipart request
      final request = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );
      final requestFields = {
        'upload_preset': uploadPreset,
        'folder': folder,
        'public_id': '${groupId}_${expenseId}_expensephoto',
      };

      print('🔍 DEBUG: Request fields: $requestFields');

      final imageBytes = await imageFile.readAsBytes();
      print('🔍 DEBUG: Image file size: ${imageBytes.length} bytes');

      final requestMultipart = http.MultipartRequest('POST', request);
      requestMultipart.fields.addAll(requestFields);
      requestMultipart.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: 'expensephoto.jpg',
        ),
      );

      print('🔍 DEBUG: Making HTTP request to Cloudinary...');
      final response = await requestMultipart.send();

      print('🔍 DEBUG: Response status code: ${response.statusCode}');
      print('🔍 DEBUG: Response headers: ${response.headers}');

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        print('🔍 DEBUG: Response data: $responseData');

        final jsonResponse = json.decode(responseData);
        final secureUrl = jsonResponse['secure_url'];
        print('🔍 DEBUG: Upload successful! Secure URL: $secureUrl');

        return secureUrl;
      } else {
        final responseData = await response.stream.bytesToString();
        print('🔍 DEBUG: Upload failed with status ${response.statusCode}');
        print('🔍 DEBUG: Error response data: $responseData');

        throw Exception(
          'Upload failed with status: ${response.statusCode}. Response: $responseData',
        );
      }
    } catch (e) {
      print('🔍 DEBUG: Exception occurred during upload: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  // SUBMIT (Firebase Implementation)
  Future<void> _onSubmit() async {
    print('🔍 DEBUG: Starting expense submission process...');
    print(
      '🔍 DEBUG: Amount: ${_amountController.text}, Description: ${_descriptionController.text}',
    );
    print('🔍 DEBUG: Selected Group: $_selectedGroup ($_selectedGroupId)');
    print('🔍 DEBUG: Tagged People: $_taggedPeople');
    print('🔍 DEBUG: Image selected: ${_selectedImage != null ? 'Yes' : 'No'}');

    if (!_isButtonEnabled || _isSubmitting) {
      print('🔍 DEBUG: Submit button not enabled or already submitting');
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
        print('🔍 DEBUG: Starting image upload for expense...');
        try {
          imageUrl = await _uploadImageToCloudinary(
            _selectedImage!,
            _selectedGroupId!,
            expenseId,
          );
          print('🔍 DEBUG: Image upload completed successfully');
        } catch (e) {
          print('🔍 DEBUG: Image upload failed: $e');
          rethrow; // Re-throw to be caught by outer catch block
        }
      } else {
        print('🔍 DEBUG: No image selected for upload');
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
      await FirebaseFirestore.instance.collection('users').doc(userDoc.id).set({
        'expensesAdded': FieldValue.increment(1),
        'totalSpent': FieldValue.increment(totalAmount),
        // 'totalKarmaPoints' removed - will be calculated dynamically from all groups
      }, SetOptions(merge: true));

      // Update group statistics - use total amount instead of karma points for total group karma
      print('🔍 DEBUG: Updating group statistics with amount: $totalAmount');
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(_selectedGroupId!)
          .set({
            'totalKarmaPoints': FieldValue.increment(
              totalAmount,
            ), // Changed: sum of all expenses
            'lastActivity': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      // Update top contributor information
      print('🔍 DEBUG: Updating top contributor for user: $username');
      await _updateTopContributor(
        _selectedGroupId!,
        username,
        totalAmount,
        userPhotoUrl,
      );

      // Update member ranks in the group
      print('🔍 DEBUG: Updating member ranks in group');
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
      print(
        '🔍 DEBUG: Updating totalKarmaPoints in users collection for creator',
      );
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
        print(
          '🔍 DEBUG: Updating totalKarmaPoints in users collection for tagged person: $taggedPerson',
        );
        await _updateUserTotalKarmaPointsInCollection(taggedPerson);
      }

      // Show success message
      print('🔍 DEBUG: Showing success snackbar...');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense added successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear form and navigate back
      print('🔍 DEBUG: Clearing form...');
      _clearForm();
      print('🔍 DEBUG: Form cleared, navigating back...');
      Navigator.pop(context);
      print('🔍 DEBUG: Navigation completed');
    } catch (e) {
      print('🔍 DEBUG: Caught exception in _onSubmit: $e');
      print('🔍 DEBUG: Exception type: ${e.runtimeType}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add expense: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );

      // Re-enable button
      setState(() {
        _isSubmitting = false;
        _isButtonEnabled = true;
      });
    }
  }

  void _clearForm() {
    print('🔍 DEBUG: _clearForm() called');
    print('🔍 DEBUG: Clearing amount controller...');
    _amountController.clear();
    print('🔍 DEBUG: Clearing description controller...');
    _descriptionController.clear();
    print('🔍 DEBUG: Resetting state variables...');
    setState(() {
      _selectedGroup = null;
      _selectedGroupId = null;
      _selectedImage = null;
      _taggedPeople = []; // Clear tagged people as well
      _isSubmitting = false;
    });
    print('🔍 DEBUG: _clearForm() completed');
  }

  // Helper method to get filtered group members (excluding current user)
  List<String> _getFilteredGroupMembers(String groupName) {
    final members = _groupMembers[groupName] ?? [];
    if (_currentUsername == null) {
      return members;
    }
    return members.where((member) => member != _currentUsername).toList();
  }

  // TOP CONTRIBUTOR UPDATE
  Future<void> _updateTopContributor(
    String groupId,
    String username,
    double amountSpent,
    String userPhotoUrl,
  ) async {
    try {
      // Get current group data
      final groupDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .get();

      if (!groupDoc.exists) return;

      final groupData = groupDoc.data() ?? {};
      final currentTopContributor = groupData['topContributor'] as String?;
      final currentTopContributorKarmaPoints =
          (groupData['topContributorKarmaPoints'] as num?)?.toDouble() ?? 0.0;

      // Get current user's total spent from members subcollection
      final memberDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .collection('members')
          .doc(username)
          .get();

      double userTotalSpent = amountSpent; // This is the new expense amount
      if (memberDoc.exists) {
        final memberData = memberDoc.data() ?? {};
        final previousSpent = (memberData['spent'] as num?)?.toDouble() ?? 0.0;
        userTotalSpent = previousSpent + amountSpent; // Total spent by user
      }

      // Check if this user should be the new top contributor
      if (currentTopContributor == null ||
          userTotalSpent > currentTopContributorKarmaPoints) {
        // Update top contributor information
        await FirebaseFirestore.instance.collection('groups').doc(groupId).set({
          'topContributor': username,
          'topContributorKarmaPoints': userTotalSpent,
          'topContributorImageUrl': userPhotoUrl,
        }, SetOptions(merge: true));

        print(
          '🔍 DEBUG: Updated top contributor to $username with $userTotalSpent spent',
        );
      }
    } catch (e) {
      print('🔍 DEBUG: Error updating top contributor: $e');
      // Don't throw error to avoid breaking the main flow
    }
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

        print('🔍 DEBUG: Updated rank for $username: $rank');
      }

      print('🔍 DEBUG: Updated ranks for ${allMembers.length} members');
    } catch (e) {
      print('🔍 DEBUG: Error updating member ranks: $e');
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

        print(
          '🔍 DEBUG: Updated totalKarmaPoints for $username to $totalKarmaPoints in users collection',
        );
      }
    } catch (e) {
      print(
        '🔍 DEBUG: Error updating totalKarmaPoints in users collection: $e',
      );
      // Don't throw error to avoid breaking the main flow
    }
  }

  // BUILD
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Add Expense",
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
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
