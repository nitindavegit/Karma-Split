import 'package:flutter/material.dart';
import 'package:karma_split/widgets/ranking_card.dart';
import 'package:karma_split/widgets/recent_activity_card.dart';
import 'package:karma_split/widgets/stat_card.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // profile card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // pfp
                    const CircleAvatar(
                      radius: 35,
                      backgroundImage: AssetImage("assets/images/JD.jpg"),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      children: [
                        // name
                        Text(
                          "Nitin Dave",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // username
                        Text(
                          "nitindave21",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Expanded(
                    child: StatCard(
                      value: "334",
                      label: "Total Karma Points",
                      icon: Icons.emoji_events,
                      iconColor: Colors.orange,
                    ),
                  ),
                  Expanded(
                    child: StatCard(
                      value: "2",
                      label: "Groups Joined",
                      icon: Icons.group,
                      iconColor: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: StatCard(
                      value: "1",
                      label: "Expenses Added",
                      icon: Icons.receipt,
                      iconColor: Colors.green,
                    ),
                  ),
                  Expanded(
                    child: StatCard(
                      value: "\$49",
                      label: "Total Spent",
                      icon: Icons.attach_money,
                      iconColor: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Rankings
              _sectionTitle("Your Rankings"),
              const RankingCard(
                group: "College Squad",
                points: "245 karma points",
                rankBadge: "#1",
                rankDetail: "Rank 1 of 4",
              ),
              const RankingCard(
                group: "Work Friends",
                points: "89 karma points",
                rankBadge: "#2",
                rankDetail: "Rank 2 of 3",
              ),

              const SizedBox(height: 20),

              // Recent Activity
              _sectionTitle("Recent Activity"),
              const RecentActivityCard(
                title: "\$48.50 in College Squad",
                points: "+48.5",
                subtitle: "Pizza night at Mario's",
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
