import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserPlanPage extends StatelessWidget {
  const UserPlanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _ScaffoldWrapper(
        child: const Center(child: Text('Not logged in.', style: TextStyle(color: Colors.white))),
      );
    }
    return _ScaffoldWrapper(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('plans')
            .where('userId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'active')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final plans = snapshot.data!.docs;
          if (plans.isEmpty) {
            return _NoPlanCard(isWide: MediaQuery.of(context).size.width > 600);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: plans.length,
            itemBuilder: (context, i) {
              final data = plans[i].data() as Map<String, dynamic>;
              return _PlanCard(plan: data);
            },
          );
        },
      ),
    );
  }
}

class _PlanCard extends StatefulWidget {
  final Map<String, dynamic> plan;
  const _PlanCard({required this.plan});

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard> {
  late DateTime now;

  @override
  void initState() {
    super.initState();
    now = DateTime.now();
    // Update 'now' every day (86400 seconds), but for demo let's do every minute
    Future.delayed(Duration.zero, updateTime);
  }

  void updateTime() async {
    while (mounted) {
      await Future.delayed(const Duration(minutes: 1)); // change to daily for production
      setState(() {
        now = DateTime.now();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final startTimestamp = widget.plan['startDate'] as Timestamp;
    final startDate = startTimestamp.toDate();
    final planNameRaw = widget.plan['planName'] ?? 'Unknown Plan';
    final planName = planNameRaw.toLowerCase();
    final status = widget.plan['status'] ?? 'Inactive';

    int totalDays;
    if (planName.contains('future')) {
      totalDays = 80;
    } else if (planName.contains('premium')) {
      totalDays = 30;
    } else {
      totalDays = -1;
    }

    final endDate = (totalDays != -1) ? startDate.add(Duration(days: totalDays)) : DateTime(2100);

    final rawDaysPassed = now.difference(startDate).inDays;
    final daysPassed = (totalDays != -1) ? rawDaysPassed.clamp(0, totalDays) : rawDaysPassed;

    final progress = (totalDays != -1 && totalDays > 0)
        ? (daysPassed / totalDays).clamp(0.0, 1.0)
        : 0.0;

    final isExpired = (totalDays != -1) && now.isAfter(endDate);

    final planColor = planName.contains('premium')
        ? Colors.deepPurple
        : planName.contains('future')
            ? Colors.teal
            : Colors.grey;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  planName.contains('premium') ? Icons.workspace_premium : Icons.trending_up,
                  color: planColor,
                  size: 30,
                ),
                const SizedBox(width: 12),
                Text(
                  planNameRaw,
                  style: TextStyle(
                    color: planColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const Spacer(),
                Chip(
                  label: Text(
                    isExpired ? 'Expired' : status.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: isExpired ? Colors.red : planColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Start Date: ${startDate.day}/${startDate.month}/${startDate.year}',
                style: const TextStyle(fontSize: 16, color: Colors.black87)),
            Text('End Date: ${endDate.day}/${endDate.month}/${endDate.year}',
                style: const TextStyle(fontSize: 16, color: Colors.black87)),
            const SizedBox(height: 12),
            if (totalDays != -1) ...[
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade300,
                color: planColor,
                minHeight: 10,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 8),
              Text(
                '$daysPassed/$totalDays days completed',
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ] else
              const Text(
                'Unlimited Plan',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            const SizedBox(height: 8),
            Text(
              isExpired
                  ? 'This plan has expired.'
                  : 'Plan is active. Enjoy your benefits!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isExpired ? Colors.red : planColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoPlanCard extends StatelessWidget {
  final bool isWide;
  const _NoPlanCard({required this.isWide});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: isWide ? 100 : 60, color: Colors.grey),
          const SizedBox(height: 20),
          Text(
            'No Active Plan Found',
            style: TextStyle(
              fontSize: isWide ? 24 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Please subscribe to a plan to access features.',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _ScaffoldWrapper extends StatelessWidget {
  final Widget child;
  const _ScaffoldWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Plan'),
        backgroundColor: const Color(0xFF1f4037),
      ),
      body: child,
      backgroundColor: Colors.grey.shade100,
    );
  }
}