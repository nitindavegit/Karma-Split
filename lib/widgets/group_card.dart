import 'package:flutter/material.dart';
import 'package:karma_split/pages/group_detail_page.dart';
import 'package:karma_split/utils/number_formatter.dart';

class GroupCard extends StatelessWidget {
  final String groupId;
  final String title; // Name of the group
  final int noOfMembers; // No of members
  final String imageUrl; // image of group
  final double totalKarmaPoints; // total karma points of group
  final String topContributor; // top contributor of group
  final double topContributorKarmaPoints; // top contributor karma points
  final String topContributorImageUrl;
  const GroupCard({
    super.key,
    required this.groupId,
    required this.title,
    required this.noOfMembers,
    required this.imageUrl,
    required this.topContributor,
    required this.topContributorKarmaPoints,
    required this.totalKarmaPoints,
    required this.topContributorImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GroupDetailPage(groupName: title, groupId: groupId),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // img
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            //name of group
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            // row of members and total karma points
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      // People icon
                      Icon(Icons.people_alt_sharp),
                      const SizedBox(width: 8),
                      // Members
                      Expanded(
                        child: Text(
                          "$noOfMembers members",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Trophy icon
                      Icon(Icons.emoji_events),
                      const SizedBox(width: 8),
                      // total karma points
                      Flexible(
                        child: Text(
                          NumberFormatter.formatKarma(totalKarmaPoints),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // row of top contributor and its karma points
            const Text(
              "TOP CONTRIBUTOR:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      // Image of Top contributor
                      ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Image.network(
                          topContributorImageUrl,
                          height: 30,
                          width: 30,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Name of top contributor
                      Expanded(
                        child: Text(
                          topContributor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // points of top contributor
                Text(
                  NumberFormatter.formatKarmaPoints(topContributorKarmaPoints),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
