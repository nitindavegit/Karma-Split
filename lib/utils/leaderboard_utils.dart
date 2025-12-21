import 'package:cloud_firestore/cloud_firestore.dart';

Future<int> getUserRank(String userId) async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .orderBy('totalKarmaPoints', descending: true)
        .get();

    final docs = snapshot.docs;

    // Loop over sorted users to find the user's position
    for (int i = 0; i < docs.length; i++) {
      if (docs[i].data()['phone'] == userId) {
        return i + 1; // rank (1-based)
      }
    }

    return -1; // user not found
  } catch (e) {
    print('Error getting user rank: $e');
    return -1; // return -1 on error
  }
}
