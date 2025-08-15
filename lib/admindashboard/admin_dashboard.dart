import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'news_page.dart';
import 'all_users_page.dart';
import 'all_groups_page.dart';
import 'request_list_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  String adminName = '';
  String adminEmail = '';
  String? photoUrl;

  @override
  void initState() {
    super.initState();
    _fetchAdminProfile();
  }

  Future<void> _fetchAdminProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        adminName = userDoc.data()?['name'] ?? 'Admin';
        adminEmail = user.email ?? '';
        photoUrl = user.photoURL;
      });
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                adminName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(adminEmail),
              currentAccountPicture: CircleAvatar(
                backgroundImage: photoUrl != null
                    ? NetworkImage(photoUrl!)
                    : null,
                child: photoUrl == null
                    ? const Icon(Icons.admin_panel_settings, size: 40)
                    : null,
              ),
              decoration: const BoxDecoration(color: Colors.deepPurple),
              otherAccountsPictures: [
                Chip(
                  label: const Text(
                    'Admin',
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.orange,
                ),
              ],
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.article),
              title: const Text('News'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => NewsPage(isAdmin: true),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Welcome, $adminName!',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // Row for Circles
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // User Count Circle (dynamic)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildCircleBox(
                        icon: Icons.people,
                        label: "Total Users",
                        count: "...",
                        color1: Colors.blueAccent,
                        color2: Colors.lightBlue,
                      );
                    }
                    if (snapshot.hasError) {
                      return _buildCircleBox(
                        icon: Icons.people,
                        label: "Total Users",
                        count: "Err",
                        color1: Colors.blueAccent,
                        color2: Colors.lightBlue,
                      );
                    }
                    final count = snapshot.data?.docs.length ?? 0;
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AllUsersPage(),
                          ),
                        );
                      },
                      child: _buildCircleBox(
                        icon: Icons.people,
                        label: "Total Users",
                        count: "$count",
                        color1: Colors.blueAccent,
                        color2: Colors.lightBlue,
                      ),
                    );
                  },
                ),
                // Group Count Circle (dynamic, now tappable)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('groups')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildCircleBox(
                        icon: Icons.group_work,
                        label: "All Groups",
                        count: "...",
                        color1: Colors.deepPurple,
                        color2: Colors.purpleAccent,
                      );
                    }
                    if (snapshot.hasError) {
                      return _buildCircleBox(
                        icon: Icons.group_work,
                        label: "All Groups",
                        count: "Err",
                        color1: Colors.deepPurple,
                        color2: Colors.purpleAccent,
                      );
                    }
                    final count = snapshot.data?.docs.length ?? 0;
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AllGroupsPage(),
                          ),
                        );
                      },
                      child: _buildCircleBox(
                        icon: Icons.group_work,
                        label: "All Groups",
                        count: "$count",
                        color1: Colors.deepPurple,
                        color2: Colors.purpleAccent,
                      ),
                    );
                  },
                ),
              ],
            ),

            // Responsive Row for Join Request Circles
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                _RequestCircle(
                  groupName: 'free',
                  icon: Icons.group_add,
                  color1: Colors.green,
                  color2: Colors.lightGreen,
                  label: 'Free Requests',
                ),
                _RequestCircle(
                  groupName: 'premium',
                  icon: Icons.workspace_premium,
                  color1: Colors.deepPurple,
                  color2: Colors.purpleAccent,
                  label: 'Premium Requests',
                ),
                _RequestCircle(
                  groupName: 'future',
                  icon: Icons.trending_up,
                  color1: Colors.teal,
                  color2: Colors.cyan,
                  label: 'Future Requests',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleBox({
    required IconData icon,
    required String label,
    required String count,
    required Color color1,
    required Color color2,
  }) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color1, color2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 40),
            const SizedBox(height: 10),
            Text(
              count,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(label, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

class _RequestCircle extends StatelessWidget {
  final String groupName;
  final IconData icon;
  final Color color1;
  final Color color2;
  final String label;

  const _RequestCircle({
    required this.groupName,
    required this.icon,
    required this.color1,
    required this.color2,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('groupName', isEqualTo: groupName)
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return buildCircleBox(
              icon: icon,
              label: '',
              count: '...',
              color1: color1,
              color2: color2,
            );
          }
          if (snapshot.hasError) {
            return buildCircleBox(
              icon: icon,
              label: '',
              count: 'Err',
              color1: color1,
              color2: color2,
            );
          }
          final count = snapshot.data?.docs.length ?? 0;
          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RequestListPage(
                    groupName: groupName,
                    label: label,
                    icon: icon,
                    color: color1,
                  ),
                ),
              );
            },
            child: Column(
              children: [
                buildCircleBox(
                  icon: icon,
                  label: '',
                  count: '$count',
                  color1: color1,
                  color2: color2,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

Widget buildCircleBox({
  required IconData icon,
  required String label,
  required String count,
  required Color color1,
  required Color color2,
}) {
  return Container(
    width: 100,
    height: 100,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [color1, color2],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.4),
          blurRadius: 10,
          offset: const Offset(4, 4),
        ),
      ],
    ),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 40),
          const SizedBox(height: 10),
          Text(
            count,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}