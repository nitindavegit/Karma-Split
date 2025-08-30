import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:karma_split/pages/add_group_page.dart';
import 'package:karma_split/widgets/group_card.dart';

class GroupsPage extends StatelessWidget {
  const GroupsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Groups")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("groups").snapshots(),
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
                topContributorKarmaPoints: (g["topContributorKarmaPoints"] ?? 0)
                    .toDouble(),
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
  }
}
