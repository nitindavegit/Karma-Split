import 'package:flutter/material.dart';

class LeaderboardCard extends StatelessWidget {
  final int rank;
  final String name;
  final String username;
  final String avatarUrl;
  final double points;
  final String badgeImagePath;
  const LeaderboardCard({
    super.key,
    required this.rank,
    required this.name,
    required this.username,
    required this.avatarUrl,
    required this.points,
    required this.badgeImagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            // rank badge
            Image.asset(badgeImagePath, width: 50, height: 50),
            const SizedBox(width: 12),
            // Avatar
            CircleAvatar(radius: 24, backgroundImage: NetworkImage(avatarUrl)),
            const SizedBox(width: 12),
            // Name & Username
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '@$username',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            // Points
            Text(
              '$points pts',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
