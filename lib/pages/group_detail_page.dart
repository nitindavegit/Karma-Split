import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:karma_split/widgets/feed_card.dart';
import 'package:karma_split/widgets/leaderboard_card.dart';

class GroupDetailPage extends StatefulWidget {
  final String groupId; // 🔑 Firestore group doc id
  final String groupName; // for title

  const GroupDetailPage({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ---------------- FEED TAB ----------------
  Widget buildFeedTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("groups")
          .doc(widget.groupId)
          .collection("expenses")
          .orderBy("timestamp", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No expenses yet"));
        }

        final expenses = snapshot.data!.docs;
        return ListView.builder(
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final e = expenses[index].data() as Map<String, dynamic>;
            return FeedCard(
              createrImageUrl: e['creatorUrl'] ?? "assets/images/g1.jpg",
              username: e['createdBy'] ?? "Unknown",
              amount: (e['amount'] as num).toDouble(),
              description: e['description'] ?? '',
              splitWith: List<String>.from(e['splitWith'] ?? []),
              karmaPoints: (e['karmaPoints'] as num?)?.toDouble() ?? 0,
              date: (e['timestamp'] as Timestamp).toDate(),
              imageUrl: e['imageUrl'] ?? "assets/images/g1.jpg",
            );
          },
        );
      },
    );
  }

  // ---------------- LEADERBOARD TAB ----------------
  Widget buildLeaderboardTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("groups")
          .doc(widget.groupId)
          .collection("members")
          .orderBy("karmaPoints", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No leaderboard data"));
        }

        final members = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            "username": doc.id, // since username is docId
            "imageUrl": data["photoUrl"] ?? "",
            "name": data['name'] ?? '',
            "karmaPoints": (data["karmaPoints"] ?? 0).toDouble(),
          };
        }).toList();

        String badgeRankValue(rank) {
          String badgerank;
          switch (rank) {
            case 1:
              badgerank = "assets/images/firstMedalopt.png";
              break;
            case 2:
              badgerank = "assets/images/secondMedalopt.png";
              break;
            case 3:
              badgerank = "assets/images/thirdMedalopt.png";
              break;
            case 4:
              badgerank = "assets/images/fourthMedalopt.png";
              break;
            case 5:
              badgerank = "assets/images/fifthMedalopt.png";
              break;
            default:
              badgerank = "assets/images/othermedaloptfinal.png";
              break;
          }
          return badgerank;
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (int i = 0; i < members.length; i++)
              LeaderboardCard(
                rank: i + 1,
                name: members[i]["name"],
                username: members[i]["username"],
                avatarUrl: members[i]["imageUrl"],
                points: members[i]["karmaPoints"],
                badgeImagePath: badgeRankValue(i + 1),
              ),
          ],
        );
      },
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == "add_member") {
                // 👉 navigate to add member screen / dialog
                // Example:
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Add Member"),
                    content: const Text("Implement add member flow here"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Close"),
                      ),
                    ],
                  ),
                );
              } else if (value == "leave_group") {
                // 👉 implement leave group logic
                final userId =
                    "currentUsername"; // replace with logged in username
                await FirebaseFirestore.instance
                    .collection("groups")
                    .doc(widget.groupId)
                    .collection("members")
                    .doc(userId)
                    .delete();

                // Optionally: also remove group from user's profile groupsJoined
                Navigator.pop(context); // go back after leaving
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: "add_member",
                child: Text("Add Member"),
              ),
              const PopupMenuItem(
                value: "leave_group",
                child: Text("Leave Group"),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Feed"),
            Tab(text: "Leaderboard"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [buildFeedTab(), buildLeaderboardTab()],
      ),
    );
  }
}
