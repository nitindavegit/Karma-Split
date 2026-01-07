import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:karma_split/pages/add_group_page.dart';
import 'package:karma_split/widgets/group_card.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  late final Future<String?> _usernameFuture;

  @override
  void initState() {
    super.initState();
    _usernameFuture = _fetchCurrentUser();
  }

  Future<String?> _fetchCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.phoneNumber != null) {
      try {
        final userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('phone', isEqualTo: user.phoneNumber!)
            .limit(1)
            .get();

        if (userQuery.docs.isNotEmpty) {
          return userQuery.docs.first['username'];
        }
      } catch (e) {
        // Error handling without debug output
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _usernameFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final username = snapshot.data;

        if (username == null) {
          return Scaffold(
            appBar: AppBar(title: const Text("My Groups")),
            body: const Center(child: Text("Unable to load user data")),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text("My Groups")),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("groups")
                .where("members", arrayContains: username)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text("Something went wrong"));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final groups = snapshot.data!.docs;

              if (groups.isEmpty) {
                return const Center(child: Text("No groups yet, create one!"));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: groups.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final doc = groups[index];
                  final g = doc.data() as Map<String, dynamic>;

                  return GroupCard(
                    groupId: doc.id,
                    title: g["groupName"] ?? "Unnamed Group", // group name
                    noOfMembers: (g["members"] as List?)?.length ?? 0,
                    imageUrl: g["groupImageUrl"] ?? "",
                    topContributor: g["topContributor"] ?? "N/A",
                    topContributorKarmaPoints:
                        (g["topContributorKarmaPoints"] ?? 0).toDouble(),
                    totalKarmaPoints: (g["totalKarmaPoints"] ?? 0).toDouble(),
                    topContributorImageUrl: g["topContributorImageUrl"] ?? "",
                  );
                },
              );
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddGroupPage()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text("Add Group"),
          ),
        );
      },
    );
  }
}
