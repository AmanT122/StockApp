import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../messages/messages_page.dart';
import '../admindashboard/admin_private_chat_page.dart';

class AllGroupsPage extends StatelessWidget {
  const AllGroupsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final groups = [
      {
        'name': 'StockTrade',
        'subtitle': 'General group for all users',
        'icon': Icons.group,
        'color': Colors.blue,
        'gradient': [Color(0xFF2193b0), Color(0xFF6dd5ed)],
      },
      {
        'name': 'StockTrade Premium',
        'subtitle': 'Exclusive for premium members',
        'icon': Icons.workspace_premium,
        'color': Colors.deepPurple,
        'gradient': [Color(0xFF8e2de2), Color(0xFF4a00e0)],
      },
      {
        'name': 'StockTrade Future',
        'subtitle': 'Futures & advanced trading',
        'icon': Icons.trending_up,
        'color': Colors.green,
        'gradient': [Color(0xFF11998e), Color(0xFF38ef7d)],
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text(
          'All Groups',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.deepPurple),
        titleTextStyle: const TextStyle(
          color: Colors.deepPurple,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Groups Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF283E51),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Divider(thickness: 1.2),
            const SizedBox(height: 12),
            // Group cards
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: groups.length,
              separatorBuilder: (context, i) => const SizedBox(height: 18),
              itemBuilder: (context, index) {
                final group = groups[index];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => GroupChatPage(
                            groupName: group['name'] as String,
                            groupIcon: group['icon'] as IconData,
                            groupColor: group['color'] as Color,
                          ),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 18,
                          horizontal: 18,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: group['gradient'] as List<Color>,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                group['icon'] as IconData,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    group['name'] as String,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF283E51),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    group['subtitle'] as String,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF7A8BA1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Color(0xFF7A8BA1),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Divider(thickness: 1.2),
            const SizedBox(height: 16),
            const Text(
              'Admin Chat Users',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF283E51),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(thickness: 1.2),
            const SizedBox(height: 12),

            // ✅ FIXED: User chat list logic - NO INDEX REQUIRED
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('groups')
                    .doc('admin_chat')
                    .collection('messages')
                    .orderBy('timestamp', descending: true) // SIMPLIFIED - NO INDEX NEEDED
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;

                  // FILTER IN CODE INSTEAD OF QUERY (NO INDEX NEEDED)
                  final filteredDocs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final isPrivate = data['private'] == true;
                    final participants = List<String>.from(data['participants'] ?? []);
                    return isPrivate && participants.contains('admin');
                  }).toList();

                  // Use a map to store unique user info with latest message
                  final Map<String, Map<String, dynamic>> users = {};
                  for (final doc in filteredDocs) {
                    final data = doc.data() as Map<String, dynamic>;

                    // Identify the user (not admin) from participants
                    final participants = List<String>.from(data['participants'] ?? []);
                    final otherUserId = participants.firstWhere(
                      (id) => id != 'admin',
                      orElse: () => '',
                    );

                    if (otherUserId.isEmpty) continue;

                    // Get name/email depending on who sent the message
                    final isAdminSender = data['senderId'] == 'admin';
                    final userName = isAdminSender ? data['recipientName'] : data['senderName'];
                    final userEmail = isAdminSender ? data['recipientEmail'] : data['senderEmail'];
                    final messageText = data['text'] ?? '';
                    final timestamp = data['timestamp'] as Timestamp?;

                    // Only add if we don't have this user yet, or if this message is newer
                    if (!users.containsKey(otherUserId) || 
                        (timestamp != null && 
                         (users[otherUserId]!['timestamp'] == null || 
                          timestamp.toDate().isAfter(users[otherUserId]!['timestamp'].toDate())))) {
                      users[otherUserId] = {
                        'name': userName ?? 'User',
                        'email': userEmail ?? '',
                        'lastMessage': messageText,
                        'timestamp': timestamp,
                        'isAdminSender': isAdminSender,
                      };
                    }
                  }

                  if (users.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No user messages yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Users will appear here when they send messages',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  final userList = users.entries.toList();
                  // Sort by latest message timestamp
                  userList.sort((a, b) {
                    final aTime = a.value['timestamp'] as Timestamp?;
                    final bTime = b.value['timestamp'] as Timestamp?;
                    if (aTime == null && bTime == null) return 0;
                    if (aTime == null) return 1;
                    if (bTime == null) return -1;
                    return bTime.toDate().compareTo(aTime.toDate()); // Convert to DateTime for comparison
                  });

                  return ListView.separated(
                    itemCount: userList.length,
                    separatorBuilder: (context, i) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final userId = userList[index].key;
                      final user = userList[index].value;
                      final lastMessage = user['lastMessage'] as String;
                      final timestamp = user['timestamp'] as Timestamp?;
                      final isAdminSender = user['isAdminSender'] as bool;

                      return Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: isAdminSender 
                                ? Colors.orange[100] 
                                : Colors.blue[100],
                            child: Icon(
                              isAdminSender ? Icons.admin_panel_settings : Icons.person,
                              color: isAdminSender ? Colors.orange : Colors.blue,
                            ),
                          ),
                          title: Text(
                            user['name'] ?? 'User',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                lastMessage,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    isAdminSender ? Icons.reply : Icons.send,
                                    size: 14,
                                    color: isAdminSender ? Colors.orange : Colors.blue,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isAdminSender ? 'Admin replied' : 'User sent',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                  if (timestamp != null) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatTimestamp(timestamp),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.orange,
                            size: 20,
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AdminPrivateChatPage(
                                  userId: userId,
                                  userName: user['name'] ?? 'User',
                                  userEmail: user['email'] ?? '',
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final messageTime = timestamp.toDate();
    final difference = now.difference(messageTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
