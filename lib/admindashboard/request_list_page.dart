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

  Future<void> removeUserFromGroupAndPlan(
    String userId,
    String groupName,
    String planName,
  ) async {
    final groupDoc = getGroupDocName(groupName);

    await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupDoc)
        .collection('members')
        .doc(userId)
        .delete();

    final plans = await FirebaseFirestore.instance
        .collection('plans')
        .where('userId', isEqualTo: userId)
        .where('planName', isEqualTo: planName)
        .where('status', isEqualTo: 'active')
        .get();

    for (var doc in plans.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> approveRequest(DocumentSnapshot requestDoc) async {
    final data = requestDoc.data() as Map<String, dynamic>;
    final userId = data['userId'];
    final userName = data['userName'];
    final userEmail = data['userEmail'];
    final planType = data['type'];
    final reqGroupName = data['groupName'];
    final groupDoc = getGroupDocName(reqGroupName);

    int durationDays;
    if (planType == "Premium Plan") {
      durationDays = 30;
    } else if (planType == "Future Plan") {
      durationDays = 80;
    } else {
      durationDays = 0;
    }

    final now = DateTime.now();
    final endDate = now.add(Duration(days: durationDays));

    await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupDoc)
        .collection('members')
        .doc(userId)
        .set({
          'userId': userId,
          'userName': userName,
          'joinedAt': now,
          'planType': planType,
          'status': 'active',
        });

    await FirebaseFirestore.instance.collection('plans').add({
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'planName': planType,
      'startDate': now,
      'endDate': endDate,
      'status': 'active',
    });

    await requestDoc.reference.update({
      'status': 'approved',
      'approvedAt': DateTime.now(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final groupDocName = getGroupDocName(groupName);

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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(data['userName'] ?? 'User'),
                        subtitle: Text(data['userEmail'] ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.check,
                                color: Colors.green,
                                size: 28,
                              ),
                              onPressed: () async {
                                await approveRequest(doc);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'User approved and added to group.',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                color: Colors.red,
                                size: 28,
                              ),
                              onPressed: () async {
                                await doc.reference.delete();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Request rejected.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              },
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Icon(Icons.verified_user, color: Colors.blue),
                        ),
                        title: Text(data['userName'] ?? 'User'),
                        subtitle: Text(data['userEmail'] ?? ''),
                        trailing: IconButton(
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
                                    onPressed: () => Navigator.pop(ctx, false),
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
                                data['planName'] ?? data['type'],
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
