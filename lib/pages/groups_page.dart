import 'package:flutter/material.dart';
import 'package:karma_split/pages/add_group_page.dart';
import 'package:karma_split/widgets/group_card.dart';

class GroupsPage extends StatelessWidget {
  const GroupsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample data
    final groups = [
      {
        "title": "Flutter Devs",
        "noOfMembers": 25,
        "imageUrl": "assets/images/g1.jpg",
        "totalKarmaPoints": 1200,
        "topContributor": "Alice",
        "topContributorKarmaPoints": 320,
        "topContributorImageUrl": "assets/images/JD.jpg",
      },
      {
        "title": "AI Enthusiasts",
        "noOfMembers": 18,
        "imageUrl": "assets/images/g2.jpg",
        "totalKarmaPoints": 950,
        "topContributor": "Bob",
        "topContributorKarmaPoints": 280,
        "topContributorImageUrl": "assets/images/RDJ.jpg",
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Your Groups",
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.separated(
          itemBuilder: (context, index) {
            final g = groups[index];
            return GroupCard(
              title: g["title"] as String,
              noOfMembers: g["noOfMembers"] as int,
              imageUrl: g["imageUrl"] as String,
              topContributor: g["topContributor"] as String,
              topContributorKarmaPoints: g["topContributorKarmaPoints"] as int,
              totalKarmaPoints: g["totalKarmaPoints"] as int,
              topContributorImageUrl: g["topContributorImageUrl"] as String,
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemCount: groups.length,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AddGroupPage(), // Your Add Group screen widget
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text("Add group"),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
