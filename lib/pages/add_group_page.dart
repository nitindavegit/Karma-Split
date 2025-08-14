import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// Mock contact model
class Contact {
  final String id;
  final String name;
  final String username;
  final String? avatar;

  Contact({
    required this.id,
    required this.name,
    required this.username,
    this.avatar,
  });
}

class AddGroupPage extends StatefulWidget {
  const AddGroupPage({super.key});

  @override
  State<AddGroupPage> createState() => _AddGroupPageState();
}

class _AddGroupPageState extends State<AddGroupPage> {
  final _groupNameController = TextEditingController();
  final _memberController = TextEditingController();
  final List<Contact> members = [];
  final List<Contact> _suggestions = [];
  File? _groupImage;

  // Mock contact data - replace with actual contact fetching
  final List<Contact> allContacts = [
    Contact(id: '1', name: 'John Doe', username: '@johndoe', avatar: null),
    Contact(id: '2', name: 'Jane Smith', username: '@janesmith', avatar: null),
    Contact(id: '3', name: 'Bob Wilson', username: '@bobwilson', avatar: null),
    Contact(id: '4', name: 'Alice Johnson', username: '@alicej', avatar: null),
    Contact(
      id: '5',
      name: 'Charlie Brown',
      username: '@charlieb',
      avatar: null,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _memberController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _memberController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _suggestions.clear();
      } else {
        _suggestions.clear();
        _suggestions.addAll(
          allContacts
              .where(
                (contact) =>
                    (contact.name.toLowerCase().contains(query) ||
                        contact.username.toLowerCase().contains(query)) &&
                    !members.contains(contact),
              )
              .take(5)
              .toList(),
        );
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked != null) {
      setState(() {
        _groupImage = File(picked.path);
      });
    }
  }

  void _addMemberFromSuggestion(Contact contact) {
    setState(() {
      members.add(contact);
      _memberController.clear();
      _suggestions.clear();
    });
  }

  void _addMemberManually() {
    final username = _memberController.text.trim();
    if (username.isNotEmpty) {
      final newContact = Contact(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: username.replaceAll('@', ''),
        username: username.startsWith('@') ? username : '@$username',
      );

      if (!members.any((m) => m.username == newContact.username)) {
        setState(() {
          members.add(newContact);
          _memberController.clear();
          _suggestions.clear();
        });
      }
    }
  }

  void _removeMember(Contact member) {
    setState(() {
      members.remove(member);
    });
  }

  void _showContactPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Add Members",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Done"),
                    ),
                  ],
                ),
              ),

              // Search field
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search contacts...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                ),
              ),

              // Contact list
              Expanded(
                child: ListView.builder(
                  itemCount: allContacts.length,
                  itemBuilder: (context, index) {
                    final contact = allContacts[index];
                    final isSelected = members.contains(contact);

                    return CheckboxListTile(
                      secondary: CircleAvatar(
                        backgroundColor: Colors.blue.shade200,
                        child: Text(
                          contact.name[0].toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      title: Text(
                        contact.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        contact.username,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      value: isSelected,
                      activeColor: Colors.blue,
                      onChanged: (bool? value) {
                        setState(() {
                          setModalState(() {
                            if (value == true) {
                              members.add(contact);
                            } else {
                              members.remove(contact);
                            }
                          });
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _createGroup() {
    if (_groupNameController.text.trim().isEmpty || _groupImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add group name and image')),
      );
      return;
    }
    // Here you will call API to create the group
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Group"), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Image picker
            Center(
              child: GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder: (_) => SafeArea(
                      child: Wrap(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.camera_alt),
                            title: const Text('Take Photo'),
                            onTap: () {
                              Navigator.pop(context);
                              _pickImage(ImageSource.camera);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.photo_library),
                            title: const Text('Choose from Gallery'),
                            onTap: () {
                              Navigator.pop(context);
                              _pickImage(ImageSource.gallery);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade100,
                    backgroundImage: _groupImage != null
                        ? FileImage(_groupImage!)
                        : null,
                    child: _groupImage == null
                        ? Icon(
                            Icons.camera_alt,
                            size: 40,
                            color: Colors.grey.shade400,
                          )
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Group Name Field
            TextField(
              controller: _groupNameController,
              decoration: InputDecoration(
                labelText: "Group Name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 20),

            // Add Members Section
            Row(
              children: [
                const Text(
                  "Add Members",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _showContactPicker,
                  icon: const Icon(Icons.contacts),
                  label: const Text("Browse Contacts"),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Search/Add Members Field
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _memberController,
                        decoration: InputDecoration(
                          hintText: "Search or enter @username",
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _addMemberManually,
                      icon: const Icon(Icons.add_circle),
                      color: Colors.blue,
                      iconSize: 28,
                    ),
                  ],
                ),

                // Suggestions dropdown
                if (_suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade300,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        final contact = _suggestions[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade200,
                            child: Text(
                              contact.name[0].toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          title: Text(contact.name),
                          subtitle: Text(contact.username),
                          trailing: const Icon(
                            Icons.add_circle_outline,
                            color: Colors.blue,
                          ),
                          onTap: () => _addMemberFromSuggestion(contact),
                        );
                      },
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Selected Members
            if (members.isNotEmpty) ...[
              Text(
                "Selected Members (${members.length})",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: members
                    .map(
                      (member) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.blue.shade200,
                              child: Text(
                                member.name[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              member.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _removeMember(member),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
            ],

            const SizedBox(height: 30),

            // Create Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _createGroup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  "Create Group",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _memberController.dispose();
    super.dispose();
  }
}
