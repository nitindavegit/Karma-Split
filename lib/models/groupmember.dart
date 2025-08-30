import 'package:cloud_firestore/cloud_firestore.dart';

class Groupmember {
  final String username;
  final String photoUrl;
  final double karmaPoints; // within this group
  final double spent; // within this group
  final int expensesAdded; // within this group

  Groupmember({
    required this.username,
    required this.photoUrl,
    this.karmaPoints = 0.0,
    this.spent = 0.0,
    this.expensesAdded = 0,
  });

  factory Groupmember.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Groupmember(
      username: doc.id,
      photoUrl: data['photoUrl'] ?? '',
      karmaPoints: (data['karmaPoints'] ?? 0).toDouble(),
      spent: (data['spent'] ?? 0).toDouble(),
      expensesAdded: (data['expensesAdded'] ?? 0).toInt(),
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'photoUrl': photoUrl,
      'karmaPoints': karmaPoints,
      'spent': spent,
      'expensesAdded': expensesAdded,
    };
  }
}
