import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String username;
  final String name;
  final String phone;
  final String photoUrl; // Image of the user
  final double totalKarmaPoints; // global karma for the profile page
  final int groupsJoined;
  final int expensesAdded;
  final double totalSpent;

  User({
    required this.name,
    required this.username,
    required this.phone,
    required this.photoUrl,
    this.totalKarmaPoints = 0.0,
    this.expensesAdded = 0,
    this.groupsJoined = 0,
    required this.id,
    this.totalSpent = 0.0,
  });

  // converting map to dart object for queries
  factory User.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      name: data['name'] ?? '',
      username: data['username'] ?? '',
      phone: data['phone'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      totalKarmaPoints: (data['totalKarmaPoints'] ?? 0).toDouble(),
      expensesAdded: (data['expensesAdded'] ?? 0).toInt(),
      groupsJoined: (data['groupsJoined'] ?? 0).toInt(),
      id: doc.id,
      totalSpent: (data['totalSpent'] ?? 0).toDouble(),
    );
  }

  // converting dart to map for sending data
  Map<String, dynamic> toMap() {
    return {
      'username': username,
      "name": name,
      "phone": phone,
      "photoUrl": photoUrl,
      "totalKarmaPoints": totalKarmaPoints,
      "totalSpent": totalSpent,
      "expensesAdded": expensesAdded,
      "groupsJoined": groupsJoined,
    };
  }
}
