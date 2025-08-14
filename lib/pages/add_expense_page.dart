import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:karma_split/widgets/amount_spent.dart';
import 'package:karma_split/widgets/description.dart';
import 'package:karma_split/widgets/proof_image.dart';
import 'package:karma_split/widgets/select_group.dart';
import 'package:karma_split/widgets/tag_people_card.dart';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  String? _selectedGroup;
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  final List<String> groups = [
    'College Squad',
    'Work Friends',
  ]; // isko dynamically laana h

  bool _isButtonEnabled = false;

  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_updateButtonState);
    _descriptionController.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    setState(() {
      _isButtonEnabled =
          _amountController.text.trim().isNotEmpty &&
          _descriptionController.text.trim().isNotEmpty &&
          _selectedGroup != null &&
          _selectedImage != null;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onGroupSelected(String group) {
    setState(() {
      _selectedGroup = group;
      _updateButtonState();
    });
  }

  Future<void> _onTakePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _selectedImage = File(photo.path);
        _updateButtonState();
      });
    }
  }

  Future<void> _onChooseFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _updateButtonState();
      });
    }
  }

  void _onSubmit() {
    if (_selectedGroup == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a group')));
      return;
    }

    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter an amount')));
      return;
    }

    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter any description')),
      );
      return;
    }
    if (_selectedImage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please upload photo')));
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Add Expense",
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            SelectGroup(
              groups: groups,
              selectedGroup: _selectedGroup,
              onGroupSelected: _onGroupSelected,
            ),
            const SizedBox(height: 16),
            AmountSpent(controller: _amountController),
            const SizedBox(height: 16),
            Description(controller: _descriptionController),
            const SizedBox(height: 16),
            TagPeopleCard(
              groupMembers: [
                'nitindave',
                'john_doe',
                'sarah_w',
                'alex123',
                'mike',
                'priya',
              ],
            ),
            const SizedBox(height: 16),
            ProofImage(
              onTakePhoto: _onTakePhoto,
              onChooseFromGallery: _onChooseFromGallery,
            ),
            const SizedBox(height: 32),
            if (_selectedImage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: ClipRRect(
                  borderRadius: BorderRadiusGeometry.circular(12),
                  child: Image.file(
                    _selectedImage!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isButtonEnabled ? _onSubmit : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: _isButtonEnabled
                    ? const Color(0xFF6A1B9A)
                    : Colors.grey,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Submit Expense',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
