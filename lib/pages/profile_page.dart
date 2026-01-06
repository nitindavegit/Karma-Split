import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:karma_split/widgets/ranking_card.dart';
import 'package:karma_split/widgets/recent_activity_card.dart';
import 'package:karma_split/widgets/stat_card.dart';
import 'package:karma_split/utils/karma_calculator.dart';
import 'package:karma_split/utils/number_formatter.dart';
import 'package:karma_split/pages/auth_choice_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  String? username;
  double totalKarmaPoints = 0.0; // Calculated from all groups
  bool isLoading = true;
  bool isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.phoneNumber == null) {
        if (mounted) setState(() => isLoading = false);
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: user.phoneNumber!)
          .get();

      if (snapshot.docs.isEmpty) {
        if (mounted) setState(() => isLoading = false);
        return;
      }

      userData = snapshot.docs.first.data();
      username = userData!["username"];

      // Calculate total karma points from all groups
      totalKarmaPoints = await KarmaCalculator.calculateUserTotalKarmaPoints(
        username!,
      );

      if (mounted) setState(() => isLoading = false);
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupsRef = FirebaseFirestore.instance.collection('groups');

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (userData == null) {
      return const Scaffold(body: Center(child: Text("User data not found.")));
    }

    return SafeArea(
      child: PopScope(
        canPop: !isLoggingOut,
        child: Scaffold(
          backgroundColor: Colors.grey[100],
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // PROFILE CARD
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
                        backgroundImage: (userData!["photoUrl"] ?? "") != ""
                            ? NetworkImage(userData!["photoUrl"])
                            : const AssetImage("assets/images/JD.jpg")
                                  as ImageProvider,
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userData!['name'] ?? "No Name",
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

                // STATS
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        value: NumberFormatter.formatDouble(totalKarmaPoints),
                        label: "Total Karma Points",
                        icon: Icons.emoji_events,
                        iconColor: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        value: "${userData!['groupsJoined'] ?? 0}",
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
                        value: "${userData!['expensesAdded'] ?? 0}",
                        label: "Expenses Added",
                        icon: Icons.receipt,
                        iconColor: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        value: NumberFormatter.formatCurrency(
                          userData!['totalSpent'] ?? 0,
                        ),
                        label: "Total Spent",
                        icon: Icons.currency_rupee,
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
                    if (!groupsSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final allGroups = groupsSnapshot.data!.docs;

                    return FutureBuilder<List<Widget>>(
                      future: _buildRankingCards(allGroups, username!),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        return Column(children: snapshot.data!);
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
                    if (!groupsSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return FutureBuilder<List<Widget>>(
                      future: _buildActivityCards(
                        groupsSnapshot.data!.docs,
                        username!,
                      ),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        return Column(children: snapshot.data!);
                      },
                    );
                  },
                ),

                const SizedBox(height: 20),

                // LOGOUT BUTTON
                ElevatedButton(
                  onPressed: isLoggingOut
                      ? null
                      : () async {
                          setState(() => isLoggingOut = true);
                          try {
                            await FirebaseAuth.instance.signOut();
                            // Navigate to auth choice page
                            if (mounted && context.mounted) {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => const AuthChoicePage(),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              setState(() => isLoggingOut = false);
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoggingOut
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text("Logout"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // BUILD RANK CARDS
  static Future<List<Widget>> _buildRankingCards(
    List<QueryDocumentSnapshot> groups,
    String username,
  ) async {
    List<Widget> cards = [];

    for (var groupDoc in groups) {
      try {
        final memberDoc = await groupDoc.reference
            .collection('members')
            .doc(username)
            .get();

        if (!memberDoc.exists) continue;

        final memberData = memberDoc.data() as Map<String, dynamic>;
        final groupData = groupDoc.data() as Map<String, dynamic>;
        final groupName = groupData['groupName'] ?? 'Unnamed Group';

        final membersSnapshot = await groupDoc.reference
            .collection('members')
            .orderBy('karmaPoints', descending: true)
            .get();

        final allMembers = membersSnapshot.docs;
        final rankIndex = allMembers.indexWhere((m) => m.id == username);
        final rank = rankIndex == -1 ? "?" : (rankIndex + 1).toString();

        final points = NumberFormatter.formatDynamic(
          memberData['karmaPoints'] ?? 0,
        );

        cards.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: RankingCard(
              group: groupName,
              points: "$points karma points",
              rankBadge: "#$rank",
              rankDetail: "Rank $rank of ${allMembers.length}",
            ),
          ),
        );
      } catch (_) {}
    }

    return cards;
  }

  // BUILD ACTIVITY CARDS
  static Future<List<Widget>> _buildActivityCards(
    List<QueryDocumentSnapshot> groups,
    String username,
  ) async {
    List<Map<String, dynamic>> activities = [];

    for (var groupDoc in groups) {
      final groupData = groupDoc.data() as Map<String, dynamic>;
      final groupName = groupData['groupName'];

      final expensesSnapshot = await groupDoc.reference
          .collection('expenses')
          .get();

      for (var expense in expensesSnapshot.docs) {
        final data = expense.data();

        if (data['createdBy'] == username) {
          activities.add({
            'groupName': groupName,
            'data': data,
            'timestamp': data['timestamp'] as Timestamp?,
          });
        }
      }
    }

    activities.sort((a, b) {
      final t1 = a['timestamp']?.toDate() ?? DateTime(0);
      final t2 = b['timestamp']?.toDate() ?? DateTime(0);
      return t2.compareTo(t1);
    });

    final recent = activities.take(3).toList();

    return recent.map((activity) {
      final data = activity['data'];
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: RecentActivityCard(
          title:
              "${NumberFormatter.formatCurrency(data['amount'])} in ${activity['groupName']}",
          points: "+${NumberFormatter.formatDynamic(data['karmaPoints'])}",
          subtitle: data['description'] ?? "",
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
