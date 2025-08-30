import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String id; // unique id
  final String name; // name of the group
  final String imageUrl; // image of the group
  final List<String> members; // members as usernames
  final double totalKarmaPoints; // total points of group
  final String? topContributor; // username of the top contributor
  final double? topContributorKarmaPoints;
  final String? topContributorImageUrl;
  final String createdBy; // username of the Creator

  Group({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.topContributor,
    required this.members,
    this.topContributorImageUrl,
    this.topContributorKarmaPoints,
    this.totalKarmaPoints = 0.0,
    required this.createdBy,
  });

  factory Group.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Group(
      id: doc.id,
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      members: List<String>.from(data['members'] ?? []),
      totalKarmaPoints: (data['totalKarmaPoints'] ?? 0).toDouble(),
      topContributor: data['topContributor'],
      topContributorKarmaPoints: data['topContributorKarmaPoints'],
      topContributorImageUrl: data['topContributorImageUrl'],
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "imageUrl": imageUrl,
      "members": members,
      "totalKarmaPoints": totalKarmaPoints,
      "topContributor": topContributor,
      "topContributorKarmaPoints": topContributorKarmaPoints,
      "topContributorImageUrl": topContributorImageUrl,
      "createdBy": createdBy,
    };
  }
}
