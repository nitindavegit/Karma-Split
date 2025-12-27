import 'package:cloud_firestore/cloud_firestore.dart';

/// Utility functions for karma calculations
class KarmaCalculator {
  /// Calculate user's total karma points from all groups they belong to
  static Future<double> calculateUserTotalKarmaPoints(String username) async {
    try {
      print('🔍 DEBUG: Calculating total karma points for user: $username');

      // Get all groups that contain this user
      final groupsQuery = await FirebaseFirestore.instance
          .collection('groups')
          .where('members', arrayContains: username)
          .get();

      double totalKarmaPoints = 0.0;

      // For each group, get the user's karma points
      for (final groupDoc in groupsQuery.docs) {
        final groupId = groupDoc.id;

        final memberDoc = await FirebaseFirestore.instance
            .collection('groups')
            .doc(groupId)
            .collection('members')
            .doc(username)
            .get();

        if (memberDoc.exists) {
          final memberData = memberDoc.data() ?? {};
          final karmaPoints =
              (memberData['karmaPoints'] as num?)?.toDouble() ?? 0.0;
          totalKarmaPoints += karmaPoints;

          print('🔍 DEBUG: Group $groupId: $karmaPoints karma points');
        }
      }

      print('🔍 DEBUG: Total karma points for $username: $totalKarmaPoints');
      return totalKarmaPoints;
    } catch (e) {
      print('🔍 DEBUG: Error calculating total karma points: $e');
      return 0.0;
    }
  }
}
