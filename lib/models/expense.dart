import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final double amount;
  final String description;
  final String createdBy; // username
  final String creatorUrl; // pfp
  final List<String> splitWith;
  final double karmaPoints; // of creator
  final String imageUrl; // image of expense
  final DateTime timestamp;

  Expense({
    required this.id,
    required this.amount,
    required this.description,
    required this.createdBy,
    required this.splitWith,
    required this.karmaPoints,
    required this.imageUrl,
    required this.timestamp,
    required this.creatorUrl,
  });

  factory Expense.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Expense(
      id: doc.id,
      amount: (data['amount'] ?? 0).toDouble(),
      description: data['description'] ?? '',
      createdBy: data['createdBy'] ?? '',
      creatorUrl: data['creatorUrl'] ?? '',
      splitWith: List<String>.from(data['splitWith'] ?? []),
      karmaPoints: data['karmaPoints'] ?? 0,
      imageUrl: data['imageUrl'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
  Map<String, dynamic> toMap() {
    return {
      "amount": amount,
      "description": description,
      "createdBy": createdBy,
      "splitWith": splitWith,
      "karmaPoints": karmaPoints,
      "creatorUrl": creatorUrl,
      "imageUrl": imageUrl,
      "timestamp": Timestamp.fromDate(timestamp),
    };
  }
}
