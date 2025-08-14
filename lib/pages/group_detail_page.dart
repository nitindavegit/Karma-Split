import 'package:flutter/material.dart';
import 'package:karma_split/widgets/feed_card.dart';
import 'package:karma_split/widgets/leaderboard_card.dart';

class GroupDetailPage extends StatefulWidget {
  final String groupName;
  const GroupDetailPage({super.key, required this.groupName});

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Sample Leaderboard data
  final List<LeaderboardCard> leaderboardData = [
    LeaderboardCard(
      rank: 1,
      name: "Nitin Dave",
      username: "nitin",
      avatarUrl: "assets/images/RDJ.jpg",
      points: 1520,
      badgeImagePath: "assets/images/firstMedalopt.png",
    ),
    LeaderboardCard(
      rank: 2,
      name: "Priya Sharma",
      username: "priya",
      avatarUrl: "assets/images/RDJ.jpg",
      points: 1380,
      badgeImagePath: "assets/images/secondMedalopt.png",
    ),
    LeaderboardCard(
      rank: 3,
      name: "Ravi Kumar",
      username: "ravi",
      avatarUrl: "assets/images/RDJ.jpg",
      points: 1240,
      badgeImagePath: "assets/images/thirdMedalopt.png",
    ),
  ];

  // Sample Feed data
  final List<FeedCard> feedData = [
    FeedCard(
      username: "@nitin",
      amount: 500,
      description: "Bought snacks for the group outing 🍿",
      splitWith: ["@priya", "@ravi", "@sneha"],
      splitAmount: 125,
      karmaPoints: 10,
      date: DateTime(2025, 8, 12),
      imageUrl: "assets/images/g1.jpg",
    ),
    FeedCard(
      username: "@priya",
      amount: 1200,
      description: "Paid for weekend getaway 🏖️",
      splitWith: ["@nitin", "@ravi", "@sneha"],
      splitAmount: 300,
      karmaPoints: 20,
      date: DateTime(2025, 8, 10),
      imageUrl: "assets/images/g2.jpg",
    ),
    FeedCard(
      username: "@ravi",
      amount: 200,
      description: "Covered the cab fare 🚖",
      splitWith: ["@nitin", "@priya"],
      splitAmount: 100,
      karmaPoints: 5,
      date: DateTime(2025, 8, 8),
      imageUrl: "assets/images/g1.jpg",
    ),
  ];

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

  Widget buildLeaderboardTab() {
    return ListView.builder(
      itemCount: leaderboardData.length,
      itemBuilder: (context, index) {
        return leaderboardData[index];
      },
    );
  }

  Widget buildFeedTab() {
    return ListView.builder(
      itemCount: feedData.length,
      itemBuilder: (context, index) {
        return feedData[index];
      },
    );
  }

  void _showAddUserDialog() {
    String username = "";
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Member"),
        content: TextField(
          decoration: const InputDecoration(hintText: "@username"),
          onChanged: (value) => username = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              // API call to add member here
              print("Adding user: $username");
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _leaveGroup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Leave Group"),
        content: const Text(
          "Are you sure you want to leave this group? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              // API call to leave group here
              print("Leaving group: ${widget.groupName}");
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to groups list
            },
            child: const Text("Leave"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Feed"),
            Tab(text: "Leaderboard"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: "Add member",
            onPressed: _showAddUserDialog,
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: "Leave group",
            onPressed: _leaveGroup,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [buildFeedTab(), buildLeaderboardTab()],
      ),
    );
  }
}
