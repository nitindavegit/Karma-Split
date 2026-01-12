import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:karma_split/utils/number_formatter.dart';

class FeedCard extends StatelessWidget {
  final String username; // of the person creating expense
  final String createrImageUrl;
  final double amount;
  final String description;
  final List<String> splitWith; // usernames
  final double karmaPoints;
  final DateTime date;
  final String imageUrl; // photo of expense

  const FeedCard({
    super.key,
    required this.username,
    required this.amount,
    required this.description,
    required this.splitWith,
    required this.karmaPoints,
    required this.date,
    required this.imageUrl,
    required this.createrImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final int totalPeople = splitWith.length + 1; // creator + splitWith
    final double splitAmount = (amount / totalPeople);

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
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: NetworkImage(createrImageUrl),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "@$username",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    DateFormat('dd MMM yyyy • hh:mm a').format(date),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Amount
            Text(
              NumberFormatter.formatCurrency(amount),
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

            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(imageUrl, fit: BoxFit.cover),
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
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                    TextSpan(
                      text: splitWith.isNotEmpty
                          ? splitWith.join(", ")
                          : "No one",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    TextSpan(
                      text:
                          '\n${NumberFormatter.formatSplitAmount(splitAmount)}',
                      style: const TextStyle(
                        fontSize: 16,
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
                NumberFormatter.formatKarmaPointsDisplay(karmaPoints),
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
