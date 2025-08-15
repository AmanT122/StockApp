
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RequestListPage extends StatelessWidget {
  final String groupName;
  final String label;
  final IconData icon;
  final Color color;

  const RequestListPage({
    super.key,
    required this.groupName,
    required this.label,
    required this.icon,
    required this.color,
  });

  // Map Firestore groupName to actual group document name
  String getGroupDocName(String groupName) {
    switch (groupName) {
      case 'free':
        return 'StockTrade';
      case 'premium':
        return 'StockTrade Premium';
      case 'future':
        return 'StockTrade Future';
      default:
        return groupName;
    }
  }

  Future<void> _removeUserFromGroup(String groupName, String userId) async {
    final groupDoc = getGroupDocName(groupName);
    await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupDoc)
        .collection('members')
        .doc(userId)
        .delete();
  }

  Future<void> removeUserFromGroupAndPlan(
    String userId,
    String groupName,
  ) async {
    // 1. Remove user from group
    await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupName)
        .collection('members')
        .doc(userId)
        .delete();

    // 2. Find and delete the user's active plan for this group
    final plans = await FirebaseFirestore.instance
        .collection('plans')
        .where('userId', isEqualTo: userId)
        .where(
          'planName',
          isEqualTo: groupName,
        ) // or planType if that's what you use
        .where('status', isEqualTo: 'active')
        .get();

    for (var doc in plans.docs) {
      await doc.reference.delete();
    }
  }

  void approveRequest(DocumentSnapshot requestDoc) async {
    final data = requestDoc.data() as Map<String, dynamic>;
    final userId = data['userId'];
    final userName = data['userName'];
    final userEmail = data['userEmail'];
    final planType = data['type']; // Should be 'Premium Plan' or 'Future Plan'
    final groupName = data['groupName']; // Should match the group

    // Set plan duration based on type
    int durationDays;
    if (planType == "Premium Plan") {
      durationDays = 30;
    } else if (planType == "Future Plan") {
      durationDays = 80;
    } else {
      // Handle unknown plan type
      return;
    }

    final now = DateTime.now();
    final endDate = now.add(Duration(days: durationDays));

    // 1. Add user to the correct group
    await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupName)
        .collection('members')
        .doc(userId)
        .set({
          'userId': userId,
          'userName': userName,
          'joinedAt': now,
          'planType': planType,
          'status': 'active',
        });

    // 2. Create plan document
    await FirebaseFirestore.instance.collection('plans').add({
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'planName': planType,
      'startDate': now,
      'endDate': endDate,
      'status': 'active',
    });

    // 3. Optionally, delete the request or update its status
    await requestDoc.reference.update({
      'status': 'approved',
      'approvedAt': DateTime.now(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(label), backgroundColor: color),
      body: Column(
        children: [
          const SizedBox(height: 12),
          const Text(
            'Pending Requests',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('requests')
                  .where('groupName', isEqualTo: groupName)
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('No pending requests.'));
                }
                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withOpacity(0.15),
                          child: const Icon(
                            Icons.person,
                            color: Colors.deepPurple,
                          ),
                        ),
                        title: Text(
                          data['userName'] ?? 'User',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(data['userEmail'] ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Tooltip(
                              message: 'Approve',
                              child: IconButton(
                                icon: const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 28,
                                ),
                                onPressed: () async {
                                  // Approve: set status to approved and add to group members
                                  await doc.reference.update({
                                    'status': 'approved',
                                  });
                                  final groupDoc = getGroupDocName(groupName);
                                  await FirebaseFirestore.instance
                                      .collection('groups')
                                      .doc(groupDoc)
                                      .collection('members')
                                      .doc(data['userId'])
                                      .set({
                                        'userId': data['userId'],
                                        'userName': data['userName'],
                                        'joinedAt':
                                            FieldValue.serverTimestamp(),
                                        'status': 'active',
                                      });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'User approved and added to group!',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                              ),
                            ),
                            Tooltip(
                              message: 'Reject',
                              child: IconButton(
                                icon: const Icon(
                                  Icons.cancel,
                                  color: Colors.red,
                                  size: 28,
                                ),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Reject Request'),
                                      content: const Text(
                                        'Are you sure you want to reject this request?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: const Text(
                                            'Reject',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await doc.reference.delete();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Request rejected.'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          const Divider(),
          const Text(
            'All Approved Users',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('requests')
                  .where('groupName', isEqualTo: groupName)
                  .where('status', isEqualTo: 'approved')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('No approved users.'));
                }
                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFD1E7FF),
                          child: Icon(Icons.verified_user, color: Colors.blue),
                        ),
                        title: Text(
                          data['userName'] ?? 'User',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(data['userEmail'] ?? ''),
                        trailing: Tooltip(
                          message: 'Remove from group',
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Remove User'),
                                  content: const Text(
                                    'Are you sure you want to remove this user from the group?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text(
                                        'Remove',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await removeUserFromGroupAndPlan(
                                  data['userId'],
                                  groupName,
                                );
                                await doc.reference.delete();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('User removed from group.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
