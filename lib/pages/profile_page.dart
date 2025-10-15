import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:karma_split/widgets/ranking_card.dart';
import 'package:karma_split/widgets/recent_activity_card.dart';
import 'package:karma_split/widgets/stat_card.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Temporary test user (for demo)
    final testUserId = '9QZLIOkciZAQmSVStE1i';
    final testUsername = 'nitin123';

    final usersRef = FirebaseFirestore.instance.collection('users');
    final groupsRef = FirebaseFirestore.instance.collection('groups');

    return StreamBuilder<DocumentSnapshot>(
      stream: usersRef.doc(testUserId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text("User data not found.")),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final username = (userData['username'] ?? '') as String;

        return SafeArea(
          child: Scaffold(
            backgroundColor: Colors.grey[100],
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundImage: (userData["photoUrl"] ?? '') != ''
                              ? NetworkImage(userData["photoUrl"])
                              : const AssetImage("assets/images/JD.jpg")
                                    as ImageProvider,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userData['name'] ?? "No Name",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "@$username",
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Stats
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          value: (userData['totalKarmaPoints'] ?? 0).toString(),
                          label: "Total Karma Points",
                          icon: Icons.emoji_events,
                          iconColor: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          value: (userData['groupsJoined'] ?? 0).toString(),
                          label: "Groups Joined",
                          icon: Icons.group,
                          iconColor: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          value: (userData['expensesAdded'] ?? 0).toString(),
                          label: "Expenses Added",
                          icon: Icons.receipt,
                          iconColor: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          value: "₹${(userData['totalSpent'] ?? 0)}",
                          label: "Total Spent",
                          icon: Icons.attach_money,
                          iconColor: Colors.red,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // YOUR RANKINGS 
                  _sectionTitle("Your Rankings"),
                  StreamBuilder<QuerySnapshot>(
                    stream: groupsRef.snapshots(),
                    builder: (context, groupsSnapshot) {
                      if (!groupsSnapshot.hasData ||
                          groupsSnapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text("No ranking data available"),
                        );
                      }

                      final allGroups = groupsSnapshot.data!.docs;

                      return FutureBuilder<List<Widget>>(
                        future: _buildRankingCards(allGroups, testUsername),
                        builder: (context, futureSnapshot) {
                          if (futureSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (!futureSnapshot.hasData ||
                              futureSnapshot.data!.isEmpty) {
                            return const Center(
                              child: Text("No ranking data available"),
                            );
                          }

                          return Column(children: futureSnapshot.data!);
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // RECENT ACTIVITY 
                  _sectionTitle("Recent Activity"),
                  StreamBuilder<QuerySnapshot>(
                    stream: groupsRef.snapshots(),
                    builder: (context, groupsSnapshot) {
                      if (!groupsSnapshot.hasData ||
                          groupsSnapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text("No recent activity yet"),
                        );
                      }

                      return FutureBuilder<List<Widget>>(
                        future: _buildActivityCards(
                          groupsSnapshot.data!.docs,
                          testUsername,
                        ),
                        builder: (context, futureSnapshot) {
                          if (futureSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (!futureSnapshot.hasData ||
                              futureSnapshot.data!.isEmpty) {
                            return const Center(
                              child: Text("No recent activity yet"),
                            );
                          }

                          return Column(children: futureSnapshot.data!);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<List<Widget>> _buildRankingCards(
    List<QueryDocumentSnapshot> groups,
    String username,
  ) async {
    List<Widget> cards = [];

    for (var groupDoc in groups) {
      try {
        // Check if user is a member of this group
        final memberDoc = await groupDoc.reference
            .collection('members')
            .doc(username)
            .get();

        if (!memberDoc.exists) continue;

        final memberData = memberDoc.data() as Map<String, dynamic>;
        final groupData = groupDoc.data() as Map<String, dynamic>;
        final groupName = groupData['groupName'] ?? 'Unnamed Group';

        // Get all members sorted by karma points
        final membersSnapshot = await groupDoc.reference
            .collection('members')
            .orderBy('karmaPoints', descending: true)
            .get();

        final allMembers = membersSnapshot.docs;
        final totalMembers = allMembers.length;

        // Find user's rank
        final rankIndex = allMembers.indexWhere((m) => m.id == username);
        final rank = rankIndex == -1 ? "?" : (rankIndex + 1).toString();

        final points = (memberData['karmaPoints'] ?? 0).toStringAsFixed(1);

        cards.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: RankingCard(
              group: groupName,
              points: "$points karma points",
              rankBadge: "#$rank",
              rankDetail: "Rank $rank of $totalMembers",
            ),
          ),
        );
      } catch (e) {
        print('Error building ranking card: $e');
      }
    }

    return cards;
  }

  static Future<List<Widget>> _buildActivityCards(
    List<QueryDocumentSnapshot> groups,
    String username,
  ) async {
    List<Map<String, dynamic>> activities = [];

    for (var groupDoc in groups) {
      try {
        final groupData = groupDoc.data() as Map<String, dynamic>;
        final groupName = groupData['groupName'] ?? 'Unknown Group';

        // Get all expenses from this group
        final expensesSnapshot = await groupDoc.reference
            .collection('expenses')
            .get();

        // Filter expenses created by this user
        for (var expenseDoc in expensesSnapshot.docs) {
          final data = expenseDoc.data();
          if (data['createdBy'] == username) {
            activities.add({
              'groupName': groupName,
              'data': data,
              'timestamp': data['timestamp'] as Timestamp?,
            });
          }
        }
      } catch (e) {
        print('Error fetching activities: $e');
      }
    }

    // Sort all activities by timestamp
    activities.sort((a, b) {
      final aTime = a['timestamp'] as Timestamp?;
      final bTime = b['timestamp'] as Timestamp?;
      if (aTime == null || bTime == null) return 0;
      return bTime.compareTo(aTime);
    });

    // Take only the 3 most recent
    final recentActivities = activities.take(3).toList();

    return recentActivities.map((activity) {
      final data = activity['data'] as Map<String, dynamic>;
      final groupName = activity['groupName'] as String;
      final desc = data["description"] ?? "No description";
      final amount = (data["amount"] ?? 0).toString();
      final karma = (data["karmaPoints"] ?? 0).toString();

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: RecentActivityCard(
          title: "₹$amount in $groupName",
          points: "+$karma",
          subtitle: desc,
        ),
      );
    }).toList();
  }

  static Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
