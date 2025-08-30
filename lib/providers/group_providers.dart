import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karma_split/models/group.dart';

final groupsProvider = StreamProvider<List<Group>>((ref) {
  return FirebaseFirestore.instance
      .collection("groups")
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map((doc) => Group.fromDoc(doc)).toList(),
      );
});
