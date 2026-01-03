import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddGroupPage extends StatefulWidget {
  const AddGroupPage({super.key});

  @override
  State<AddGroupPage> createState() => _AddGroupPageState();
}

class _AddGroupPageState extends State<AddGroupPage> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _memberController = TextEditingController();
  final List<Map<String, String>> members = [];
  File? _groupImage;

  Future<void> pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _groupImage = File(pickedFile.path);
      });
    }
  }

  void addMember() async {
    final username = _memberController.text.trim();
    if (username.isEmpty) return;

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
    final photoUrl = userDoc["photoUrl"] ?? "";
    if (members.any((m) => m['username'] == username)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("⚠️ @$username already added")));
      }
      return;
    }

    setState(() {
      members.add({"username": username, "photoUrl": photoUrl});
    });
    _memberController.clear();
  }

  Future<void> createGroup() async {
    final groupName = _groupNameController.text.trim();
    if (groupName.isEmpty || members.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please enter group name and add members")),
        );
      }
      return;
    }

    final docRef = FirebaseFirestore.instance.collection("groups").doc();

    // upload image
    String? uploadedUrl;
    if (_groupImage != null) {
      final storageRef = FirebaseStorage.instance.ref().child(
        "groups/${docRef.id}.jpg",
      );
      await storageRef.putFile(_groupImage!);
      uploadedUrl = await storageRef.getDownloadURL();
    }
    final groupData = {
      "id": docRef.id,
      "name": groupName,
      "imageUrl": uploadedUrl ?? "", // later upload to Firebase Storage
      "members": members.map((m) => m['username']).toList(),
      "totalKarmaPoints": 0.0,
      "createdAt": FieldValue.serverTimestamp(),
    };

    await docRef.set(groupData);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("✅ Group '$groupName' created!")));

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Create Group")),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // group image picker
            GestureDetector(
              onTap: pickImage,
              child: CircleAvatar(
                radius: 40,
                backgroundImage: _groupImage != null
                    ? FileImage(_groupImage!)
                    : null,
                child: _groupImage == null
                    ? Icon(Icons.camera_alt, size: 40, color: Colors.grey)
                    : null,
              ),
            ),
            SizedBox(height: 16),

            // group name
            TextField(
              controller: _groupNameController,
              decoration: InputDecoration(
                labelText: "Group Name",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),

            // Add members
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _memberController,
                    decoration: InputDecoration(
                      labelText: "Add member by username",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(icon: Icon(Icons.add), onPressed: addMember),
              ],
            ),
            SizedBox(height: 16),
            // show members
            Wrap(
              spacing: 8,
              children: members.map((m) {
                return Chip(
                  avatar: CircleAvatar(
                    backgroundImage:
                        m["photoUrl"] != null && m["photoUrl"]!.isNotEmpty
                        ? NetworkImage(m['photoUrl']!)
                        : null,
                  ),
                  label: Text("@${m['username']}"),
                  onDeleted: () {
                    setState(() {
                      members.remove(m);
                    });
                  },
                );
              }).toList(),
            ),
            Spacer(),
            // create button
            ElevatedButton(
              onPressed: createGroup,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text("Create Group"),
            ),
          ],
        ),
      ),
    );
  }
}
