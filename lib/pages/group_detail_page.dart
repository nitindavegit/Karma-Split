// lib/pages/group_detail_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:karma_split/widgets/feed_card.dart';
import 'package:karma_split/widgets/leaderboard_card.dart';

class GroupDetailPage extends StatefulWidget {
  final String groupId; // Firestore doc id
  final String groupName; // UI title

  const GroupDetailPage({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

 //  String? _currentUid; // firebase uid if signed-in
  String? _currentUsername; // username from users/{uid}
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initCurrentUser();
  }

  Future<void> _initCurrentUser() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser != null) {
      // _currentUid = firebaseUser.uid;

      // Search by phone number since user documents were created with phone as ID
      final phone = firebaseUser.phoneNumber;

      if (phone != null) {
        try {
          final userQuery = await _firestore
              .collection('users')
              .where('phone', isEqualTo: phone)
              .limit(1)
              .get();

          if (userQuery.docs.isNotEmpty) {
            final userDoc = userQuery.docs.first;
            final data = userDoc.data();
            final username = (data['username'] as String?) ?? firebaseUser.uid;
            setState(() {
              _currentUsername = username;
            });
          } else {
            // fallback to UID if no user doc found
            setState(() {
              _currentUsername = firebaseUser.uid;
            });
          }
        } catch (e) {
          setState(() {
            _currentUsername = firebaseUser.uid;
          });
        }
      } else {
        // No phone number, fallback to UID
        setState(() {
          _currentUsername = firebaseUser.uid;
        });
      }
    } else {
      // Not signed in — leave _currentUsername null
    }
  }

  // --- Helpers ---
  String _safeImageUrl(String? url) {
    // return a network placeholder when url is null/empty or not http(s)
    if (url != null &&
        url.trim().isNotEmpty &&
        (url.startsWith('http://') || url.startsWith('https://'))) {
      return url;
    }
    // lightweight placeholder so NetworkImage never gets empty string
    return 'https://via.placeholder.com/400x250.png?text=No+Image';
  }

  void _showSnack(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: error ? Colors.red : null),
    );
  }

  // --- Add member flow ---
  Future<void> _showAddMemberDialog() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Member by @username'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'username (no @)'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final username = controller.text.trim();
              Navigator.pop(context);
              if (username.isNotEmpty) _addMemberByUsername(username);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _addMemberByUsername(String username) async {
    try {
      // find user doc by username in users collection
      final q = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (q.docs.isEmpty) {
        _showSnack('User @$username not found', error: true);
        return;
      }

      final userDoc = q.docs.first;
      final userData = userDoc.data();
      final uid = userDoc.id;
      final name = (userData['name'] as String?) ?? username;
      final photoUrl = (userData['photoUrl'] as String?) ?? '';

      final memberRef = _firestore
          .collection('groups')
          .doc(widget.groupId)
          .collection('members')
          .doc(username);

      final exists = (await memberRef.get()).exists;
      if (exists) {
        _showSnack('@$username is already a member', error: true);
        return;
      }

      // set member doc (username as docId)
      await memberRef.set({
        'username': username,
        'name': name,
        'photoUrl': photoUrl,
        'karmaPoints': 0.0,
        'spent': 0.0,
        'expensesAdded': 0,
      });

      // denormalized group members array (optional but useful for quick counts)
      await _firestore.collection('groups').doc(widget.groupId).set({
        'members': FieldValue.arrayUnion([username]),
      }, SetOptions(merge: true));

      // increment groupsJoined in users/{uid}
      await _firestore.collection('users').doc(uid).set({
        'groupsJoined': FieldValue.increment(1),
      }, SetOptions(merge: true));

      _showSnack('@$username added to the group');
    } catch (e) {
      _showSnack('Failed to add member', error: true);
    }
  }

  // --- Leave group flow ---
  Future<void> _showLeaveConfirm() async {
    // if current username is unknown, allow the user to type it
    if (_currentUsername == null) {
      final controller = TextEditingController();
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Leave Group'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your username to leave the group:'),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                decoration: const InputDecoration(hintText: 'username (no @)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                final uname = controller.text.trim();
                Navigator.pop(context);
                if (uname.isNotEmpty) _leaveGroup(uname);
              },
              child: const Text('Leave'),
            ),
          ],
        ),
      );
      return;
    }

    // when we do have a current username, confirm leave
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: Text('Are you sure you want to leave "${widget.groupName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _leaveGroup(_currentUsername!);
    }
  }

  Future<void> _leaveGroup(String username) async {
    try {
      final memberRef = _firestore
          .collection('groups')
          .doc(widget.groupId)
          .collection('members')
          .doc(username);

      final memberSnap = await memberRef.get();
      if (!memberSnap.exists) {
        _showSnack('You are not a member of this group', error: true);
        return;
      }

      // find user's uid to decrement groupsJoined (users collection: doc id = uid)
      final q = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      String? uid;
      if (q.docs.isNotEmpty) uid = q.docs.first.id;

      // delete from group's members subcollection
      await memberRef.delete();

      // remove from denormalized group.members array (if present)
      await _firestore.collection('groups').doc(widget.groupId).set({
        'members': FieldValue.arrayRemove([username]),
      }, SetOptions(merge: true));

      // decrement user's groupsJoined if we found a uid
      if (uid != null) {
        await _firestore.collection('users').doc(uid).set({
          'groupsJoined': FieldValue.increment(-1),
        }, SetOptions(merge: true));
      }

      _showSnack('You left ${widget.groupName}');
      // optionally pop back to groups list
      Navigator.pop(context);
    } catch (e) {
      _showSnack('Failed to leave group', error: true);
    }
  }

  // FEED TAB
  Widget buildFeedTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('groups')
          .doc(widget.groupId)
          .collection('expenses')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No expenses yet'));
        }

        final expenses = snapshot.data!.docs;
        return ListView.builder(
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final e = expenses[index].data() as Map<String, dynamic>;
            final creatorUrl = _safeImageUrl(e['creatorUrl'] as String?);
            final expenseImg = _safeImageUrl(e['imageUrl'] as String?);
            final timestamp =
                (e['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

            return FeedCard(
              createrImageUrl: creatorUrl,
              username: e['createdBy'] ?? 'unknown',
              amount: (e['amount'] as num?)?.toDouble() ?? 0.0,
              description: e['description'] ?? '',
              splitWith: List<String>.from(e['splitWith'] ?? []),
              karmaPoints: (e['karmaPoints'] as num?)?.toDouble() ?? 0.0,
              date: timestamp,
              imageUrl: expenseImg,
            );
          },
        );
      },
    );
  }

  // LEADERBOARD TAB
  Widget buildLeaderboardTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('groups')
          .doc(widget.groupId)
          .collection('members')
          .orderBy('karmaPoints', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No leaderboard data'));
        }

        final members = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'username': doc.id,
            'name': data['name'] ?? doc.id,
            'imageUrl': _safeImageUrl(data['photoUrl'] as String?),
            'karmaPoints': (data['karmaPoints'] as num?)?.toDouble() ?? 0.0,
          };
        }).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: members.length + 1,
          itemBuilder: (context, index) {
            if (index < members.length) {
              final m = members[index];
              final rank = index + 1;
              final badge = rank == 1
                  ? 'assets/images/firstMedalopt.png'
                  : rank == 2
                  ? 'assets/images/secondMedalopt.png'
                  : rank == 3
                  ? 'assets/images/thirdMedalopt.png'
                  : 'assets/images/othermedaloptfinal.png';

              return LeaderboardCard(
                rank: rank,
                name: m['name'] as String,
                username: m['username'] as String,
                avatarUrl: m['imageUrl'] as String,
                points: m['karmaPoints'] as double,
                badgeImagePath: badge,
              );
            }

            // final row: show total karma from group doc
            return StreamBuilder<DocumentSnapshot>(
              stream: _firestore
                  .collection('groups')
                  .doc(widget.groupId)
                  .snapshots(),
              builder: (context, s2) {
                if (!s2.hasData) return const SizedBox.shrink();
                final group = s2.data!.data() as Map<String, dynamic>? ?? {};
                final total =
                    (group['totalKarmaPoints'] as num?)?.toDouble() ?? 0.0;
                return Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    'Total Karma: ${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'add_member') {
                await _showAddMemberDialog();
              } else if (value == 'leave_group') {
                await _showLeaveConfirm();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'add_member',
                child: Row(
                  children: [
                    Icon(Icons.person_add, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Add Member'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'leave_group',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Leave Group'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Feed'),
            Tab(text: 'Leaderboard'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [buildFeedTab(), buildLeaderboardTab()],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
