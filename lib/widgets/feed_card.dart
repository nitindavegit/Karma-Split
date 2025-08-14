import 'package:flutter/material.dart';

class FeedCard extends StatelessWidget {
  final String username;
  final int amount;
  final String description;
  final List<String> splitWith;
  final double splitAmount;
  final double karmaPoints;
  final DateTime date;
  final String imageUrl; // image is now required

  const FeedCard({
    super.key,
    required this.username,
    required this.amount,
    required this.description,
    required this.splitWith,
    required this.splitAmount,
    required this.karmaPoints,
    required this.date,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Username and date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  username,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  "$date",
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Amount
            Text(
              "₹$amount",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 4),

            // Description
            Text(
              description,
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
            const SizedBox(height: 12),

            // Image (always present)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(imageUrl, fit: BoxFit.cover),
            ),
            const SizedBox(height: 12),

            // Split info
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(12),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Split with: ',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    TextSpan(
                      text: "$splitWith",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    TextSpan(
                      text: '\n$splitAmount each',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Karma points
            Center(
              child: Text(
                "$karmaPoints Karma Points",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
