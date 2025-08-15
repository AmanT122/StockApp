import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Removes the user from the related group and deletes the active plan.
Future<void> removeUserFromGroupAndPlan({
  required String userId,
  required String groupName,
  required String planName,
}) async {
  String getGroupDocName(String name) {
    switch (name.toLowerCase()) {
      case 'free':
        return 'StockTrade';
      case 'premium':
        return 'StockTrade Premium';
      case 'future':
        return 'StockTrade Future';
      default:
        return name;
    }
  }

  final groupDoc = getGroupDocName(groupName);
  final membersRef = FirebaseFirestore.instance
      .collection('groups')
      .doc(groupDoc)
      .collection('members');

  // Delete by document ID
  try {
    await membersRef.doc(userId).delete();
  } catch (_) {}

  // Delete where 'userId' matches
  final snap1 = await membersRef.where('userId', isEqualTo: userId).get();
  for (var doc in snap1.docs) {
    await doc.reference.delete();
  }

  // Delete where 'UserId' matches (case-sensitive)
  final snap2 = await membersRef.where('UserId', isEqualTo: userId).get();
  for (var doc in snap2.docs) {
    await doc.reference.delete();
  }

  // Delete active plans for this user
  final planSnap = await FirebaseFirestore.instance
      .collection('plans')
      .where('userId', isEqualTo: userId)
      .where('planName', isEqualTo: planName)
      .where('status', isEqualTo: 'active')
      .get();

  for (var doc in planSnap.docs) {
    await doc.reference.delete();
  }
}

class UserPlansPage extends StatefulWidget {
  final String userId;
  final String userName;

  const UserPlansPage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<UserPlansPage> createState() => _UserPlansPageState();
}

class _UserPlansPageState extends State<UserPlansPage> {
  String formatDate(dynamic date) {
    if (date is Timestamp)
      return DateFormat('dd/MM/yyyy').format(date.toDate());
    if (date is DateTime) return DateFormat('dd/MM/yyyy').format(date);
    if (date is String) {
      try {
        return DateFormat('dd/MM/yyyy').format(DateTime.parse(date));
      } catch (_) {
        return date;
      }
    }
    return 'N/A';
  }

  String getPlanCharge(String planName) {
    final p = planName.toLowerCase();
    if (p.contains('premium')) return '1999';
    if (p.contains('future')) return '2999';
    return 'N/A';
  }

  String getGroupNameFromPlanName(String planName) {
    final p = planName.toLowerCase();
    if (p.contains('premium')) return 'premium';
    if (p.contains('future')) return 'future';
    return 'free';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${widget.userName}'s Plans",
          style: const TextStyle(
            color: Colors.white, // White color for username
            fontWeight: FontWeight.bold, // Bold username
          ),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[100],
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('plans')
            .where('userId', isEqualTo: widget.userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text('No plans found.', style: TextStyle(fontSize: 18)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final planName = data['planName'] ?? 'Unknown Plan';
              final planCharge = getPlanCharge(planName);
              final start = (data['startDate'] as Timestamp?)?.toDate();

              int duration = planName.toLowerCase().contains('future')
                  ? 80
                  : 30;
              final end = start?.add(Duration(days: duration));
              final expired = end != null && end.isBefore(now);

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple, Colors.purpleAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 18,
                  ),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.workspace_premium,
                      color: expired ? Colors.red : Colors.deepPurple,
                      size: 32,
                    ),
                  ),
                  title: Text(
                    planName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      letterSpacing: 0.5,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Plan Charges: ₹$planCharge',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Start Date:  ${formatDate(start)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'End Date: ${formatDate(end)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Status: ${expired ? 'Expired' : 'Active'}',
                        style: TextStyle(
                          color: expired ? Colors.red[200] : Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.redAccent,
                      size: 28,
                    ),
                    tooltip: 'Delete Plan',
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('Delete Plan'),
                          content: Text(
                            'Are you sure you want to delete the "$planName" plan for ${widget.userName}? This will also remove them from the group.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(c, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );

                      if (confirm != true) return;

                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) =>
                            const Center(child: CircularProgressIndicator()),
                      );
                      final groupName = getGroupNameFromPlanName(planName);

                      await removeUserFromGroupAndPlan(
                        userId: widget.userId,
                        groupName: groupName,
                        planName: planName,
                      );

                      if (mounted) {
                        Navigator.pop(context); // close loader
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Deleted "$planName" and removed ${widget.userName} from group.',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                        setState(() {});
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
