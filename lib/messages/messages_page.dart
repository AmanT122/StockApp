import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final groups = [
    {
      'name': 'StockTrade',
      'subtitle': 'General group for all users',
      'icon': Icons.group,
      'color': Colors.blue,
    },
    {
      'name': 'StockTrade Premium',
      'subtitle': 'Exclusive for premium members',
      'icon': Icons.workspace_premium,
      'color': Colors.deepPurple,
    },
    {
      'name': 'StockTrade Future',
      'subtitle': 'Futures & advanced trading',
      'icon': Icons.trending_up,
      'color': Colors.green,
    },
    {
      'name': 'Admin Chat',
      'subtitle': 'Direct chat with admin',
      'icon': Icons.admin_panel_settings,
      'color': Colors.orange,
    },
  ];

  Future<bool> isUserMember(String groupName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    // Fetch user data from Firestore
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final userData = userDoc.data();
    final isAdmin =
        (userData?['role'] == 'admin') ||
        (userData?['name']?.toLowerCase() == 'admin');

    if (isAdmin) return true; // Admin can access all groups

    // Admin Chat is always accessible for everyone
    if (groupName == 'Admin Chat') return true;

    // Normal membership check for non-admins
    final doc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupName)
        .collection('members')
        .doc(user.uid)
        .get();
    return doc.exists;
  }

  @override
  void initState() {
    super.initState();
    _checkAuthenticationStatus();
  }

  void _checkAuthenticationStatus() {
    final user = FirebaseAuth.instance.currentUser;
    print(
      'Authentication status: ${user != null ? 'Authenticated' : 'Not authenticated'}',
    );
    if (user != null) {
      print('User ID: ${user.uid}');
      print('User Email: ${user.email}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF283E51), Color(0xFF485563)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: AppBar(
            title: const Text(
              'Groups',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 26,
                letterSpacing: 0.5,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 500;
          return ListView.separated(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 60 : 18,
              vertical: 32,
            ),
            itemCount: groups.length,
            separatorBuilder: (_, __) => const SizedBox(height: 28),
            itemBuilder: (context, index) {
              final group = groups[index];
              return FutureBuilder<bool>(
                future: isUserMember(group['name'] as String),
                builder: (context, snapshot) {
                  final isMember = snapshot.data ?? false;
                  return InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: () async {
                      final groupName = group['name'] as String;
                      final type = groupName == 'StockTrade'
                          ? 'normal'
                          : groupName == 'StockTrade Premium'
                          ? 'premium'
                          : groupName == 'StockTrade Future'
                          ? 'futurepremium'
                          : 'admin';
                      if (isMember) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GroupChatPage(
                              groupName: groupName,
                              groupIcon: group['icon'] as IconData,
                              groupColor: group['color'] as Color,
                            ),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => JoinGroupPage(
                              groupName: groupName,
                              groupColor: group['color'] as Color,
                              type: type,
                            ),
                          ),
                        );
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            (group['color'] as Color).withOpacity(0.13),
                            (group['color'] as Color).withOpacity(0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: (group['color'] as Color).withOpacity(0.13),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(
                          color: (group['color'] as Color).withOpacity(0.18),
                          width: 1.2,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 22,
                        ),
                        leading: CircleAvatar(
                          radius: 32,
                          backgroundColor: (group['color'] as Color)
                              .withOpacity(0.13),
                          child: Icon(
                            group['icon'] as IconData,
                            color: group['color'] as Color,
                            size: 36,
                          ),
                        ),
                        title: Text(
                          group['name'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF22223B),
                            fontSize: 22,
                            letterSpacing: 0.2,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            group['subtitle'] as String,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF4A4E69),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        trailing: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeInOut,
                          decoration: BoxDecoration(
                            color: isMember
                                ? (group['color'] as Color).withOpacity(0.85)
                                : Colors.grey[400],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Icon(
                            isMember ? Icons.arrow_forward_ios : Icons.lock,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// sendJoinRequest remains outside the class
Future<void> sendJoinRequest(String groupName, String type) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  // Fetch the user's name from the users collection
  final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();
  final userName = userDoc.data()?['name'] ?? '';

  // Map groupName to Firestore value for admin dashboard
  String mappedGroupName;
  if (groupName == 'StockTrade') {
    mappedGroupName = 'free';
  } else if (groupName == 'StockTrade Premium') {
    mappedGroupName = 'premium';
  } else if (groupName == 'StockTrade Future') {
    mappedGroupName = 'future';
  } else {
    mappedGroupName = groupName.toLowerCase();
  }

  await FirebaseFirestore.instance.collection('requests').add({
    'userEmail': user.email,
    'userName': userName,
    'userId': user.uid,
    'type': type,
    'groupName': mappedGroupName,
    'timestamp': FieldValue.serverTimestamp(),
    'status': 'pending',
  });
}

class GroupChatPage extends StatefulWidget {
  final String groupName;
  final IconData groupIcon;
  final Color groupColor;

  const GroupChatPage({
    super.key,
    required this.groupName,
    required this.groupIcon,
    required this.groupColor,
  });

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final TextEditingController _controller = TextEditingController();
  late final String groupId;
  final currentUser = FirebaseAuth.instance.currentUser;
  String? editingMessageId;
  String? editingText;

  @override
  void initState() {
    super.initState();
    groupId = widget.groupName.toLowerCase().replaceAll(' ', '_');
  }

  Future<String> _getCurrentUserName() async {
    final user = currentUser;
    if (user == null) return 'User';
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    return userDoc.data()?['name'] ?? 'User';
  }

  Future<void> _sendMessage({String? text, String? imageUrl}) async {
    if ((text == null || text.trim().isEmpty) && imageUrl == null) return;

    final user = currentUser;
    if (user == null) {
      print('User not authenticated');
      return;
    }

    try {
      final userName = await _getCurrentUserName();
      final userEmail = user.email ?? '';
      final isAdminChat = widget.groupName == 'Admin Chat';
      final adminId = 'admin';
      final messageData = {
        'text': text?.trim() ?? '',
        'senderId': isAdminChat ? user.uid : user.uid,
        'senderName': userName,
        'senderEmail': userEmail,
        'timestamp': FieldValue.serverTimestamp(),
        'private': isAdminChat,
        'participants': isAdminChat ? [adminId, user.uid] : null,
        'imageUrl': imageUrl,
      }..removeWhere((k, v) => v == null);
      if (isAdminChat) {
        await FirebaseFirestore.instance
            .collection('admin_chats')
            .doc(user.uid)
            .collection('messages')
            .add(messageData);
      } else {
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(groupId)
            .collection('messages')
            .add(messageData);
      }
    } catch (e) {
      print('Failed to send message: $e');
    }
  }

  Future<void> _editMessage(String messageId, String newText) async {
    if (widget.groupName == 'Admin Chat') {
      await FirebaseFirestore.instance
          .collection('admin_chats')
          .doc(currentUser?.uid)
          .collection('messages')
          .doc(messageId)
          .update({'text': newText, 'edited': true});
    } else {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .doc(messageId)
          .update({'text': newText, 'edited': true});
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    if (widget.groupName == 'Admin Chat') {
      await FirebaseFirestore.instance
          .collection('admin_chats')
          .doc(currentUser?.uid)
          .collection('messages')
          .doc(messageId)
          .delete();
    } else {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .doc(messageId)
          .delete();
    }
  }

  void _showMessageOptions(
    BuildContext context,
    String messageId,
    String content,
    String type,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            if (type == 'text') // Only show edit for text messages
              ListTile(
                leading: Icon(Icons.edit, color: widget.groupColor),
                title: const Text('Edit Message'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog(messageId, content);
                },
              ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Delete Message',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, messageId);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String messageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _deleteMessage(messageId);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(String messageId, String oldText) {
    final editController = TextEditingController(text: oldText);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: editController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Edit your message'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newText = editController.text.trim();
              if (newText.isNotEmpty) {
                await _editMessage(messageId, newText);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final dt = timestamp.toDate();
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$hour12:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final pastelBg = [
      const Color(0xFFe0eafc),
      const Color(0xFFcfdef3),
      const Color(0xFFf9f6ff),
    ];
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: pastelBg,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Gradient AppBar with shadow and custom group avatar
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.groupColor,
                      widget.groupColor.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.groupColor.withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.18),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white,
                        child: Icon(
                          widget.groupIcon,
                          color: widget.groupColor,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        widget.groupName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          letterSpacing: 0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Chat messages
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: widget.groupName == 'Admin Chat'
                      ? FirebaseFirestore.instance
                            .collection('admin_chats')
                            .doc(currentUser?.uid)
                            .collection('messages')
                            .orderBy('timestamp', descending: false)
                            .snapshots()
                      : FirebaseFirestore.instance
                            .collection('groups')
                            .doc(groupId)
                            .collection('messages')
                            .orderBy('timestamp', descending: false)
                            .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final messages = snapshot.data!.docs;
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 18,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final data = msg.data() as Map<String, dynamic>;
                        final isMe = data['senderId'] == currentUser?.uid;
                        String senderName =
                            data['senderName'] ?? data['sender'] ?? 'Unknown';
                        // Override senderName to 'Admin' if sender is admin
                        if ((data['senderName']?.toString().toLowerCase() ==
                                'admin') ||
                            (data['senderRole']?.toString().toLowerCase() ==
                                'admin')) {
                          senderName = 'Admin';
                        }
                        final type = data['type'] ?? 'text';
                        final content = type == 'image'
                            ? data['imageUrl']
                            : data['text'];
                        final timestamp = data['timestamp'] as Timestamp?;
                        final messageId = msg.id;
                        final edited = data['edited'] == true;
                        // Animation for new messages
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 30 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: Padding(
                            padding: EdgeInsets.only(
                              top: index == 0 ? 0 : 10,
                              bottom: index == messages.length - 1 ? 10 : 0,
                              left: isMe ? 60 : 8,
                              right: isMe ? 8 : 60,
                            ),
                            child: Column(
                              crossAxisAlignment: isMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 4,
                                    right: 4,
                                    bottom: 2,
                                  ),
                                  child: Text(
                                    senderName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isMe
                                          ? widget.groupColor
                                          : Colors.deepPurple,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onLongPress: isMe
                                      ? () {
                                          _showMessageOptions(
                                            context,
                                            messageId,
                                            content ?? '',
                                            type,
                                          );
                                        }
                                      : null,
                                  child: _GlassNeumorphicBubble(
                                    isMe: isMe,
                                    color: widget.groupColor,
                                    content: content ?? '',
                                    type: type,
                                    timestamp: _formatTimestamp(timestamp),
                                    edited: edited,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              // Message input
              _ChatInputBar(
                groupColor: widget.groupColor,
                controller: _controller,
                onSend: (text) => _sendMessage(text: text),
                onSendImage: (url) => _sendMessage(imageUrl: url),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Glassmorphic/Neumorphic message bubble widget
class _GlassNeumorphicBubble extends StatelessWidget {
  final bool isMe;
  final Color color;
  final String content;
  final String type;
  final String timestamp;
  final bool edited;
  const _GlassNeumorphicBubble({
    required this.isMe,
    required this.color,
    required this.content,
    required this.type,
    required this.timestamp,
    required this.edited,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 270),
      padding: type == 'image'
          ? const EdgeInsets.all(0)
          : const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: isMe ? color.withOpacity(0.18) : Colors.white.withOpacity(0.65),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(isMe ? 20 : 6),
          bottomRight: Radius.circular(isMe ? 6 : 20),
        ),
        boxShadow: [
          BoxShadow(
            color: isMe
                ? color.withOpacity(0.10)
                : Colors.grey.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isMe ? color.withOpacity(0.18) : Colors.grey.withOpacity(0.10),
          width: 1.1,
        ),
        backgroundBlendMode: BlendMode.overlay,
      ),
      child: type == 'image'
          ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                content,
                width: 180,
                height: 120,
                fit: BoxFit.cover,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timestamp,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    if (edited)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Text(
                          '(edited)',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              ],
            ),
    );
  }
}

// Stylish input bar with blur and rounded corners
class _ChatInputBar extends StatefulWidget {
  final Color groupColor;
  final TextEditingController controller;
  final void Function(String) onSend;
  final void Function(String) onSendImage;
  const _ChatInputBar({
    required this.groupColor,
    required this.controller,
    required this.onSend,
    required this.onSendImage,
  });
  @override
  State<_ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<_ChatInputBar> {
  bool _hoverSend = false;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border.all(
          color: widget.groupColor.withOpacity(0.13),
          width: 1.1,
        ),
        backgroundBlendMode: BlendMode.overlay,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => widget.onSendImage(
              'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80',
            ),
            child: Container(
              decoration: BoxDecoration(
                color: widget.groupColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.image, color: widget.groupColor, size: 26),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: widget.controller,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: InputBorder.none,
              ),
              minLines: 1,
              maxLines: 4,
              style: const TextStyle(fontSize: 16),
              onSubmitted: widget.onSend,
            ),
          ),
          const SizedBox(width: 6),
          MouseRegion(
            onEnter: (_) => setState(() => _hoverSend = true),
            onExit: (_) => setState(() => _hoverSend = false),
            child: GestureDetector(
              onTap: () => widget.onSend(widget.controller.text),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: _hoverSend
                      ? widget.groupColor.withOpacity(0.85)
                      : widget.groupColor.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    if (_hoverSend)
                      BoxShadow(
                        color: widget.groupColor.withOpacity(0.18),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Icon(Icons.send, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class JoinGroupPage extends StatefulWidget {
  final String groupName;
  final Color groupColor;
  final String type;
  const JoinGroupPage({
    super.key,
    required this.groupName,
    required this.groupColor,
    required this.type,
  });

  @override
  State<JoinGroupPage> createState() => _JoinGroupPageState();
}

class _JoinGroupPageState extends State<JoinGroupPage> {
  bool requested = false;

  Future<void> _requestJoin() async {
    // Use mapped group name for requests
    String mappedGroupName;
    if (widget.groupName == 'StockTrade') {
      mappedGroupName = 'free';
    } else if (widget.groupName == 'StockTrade Premium') {
      mappedGroupName = 'premium';
    } else if (widget.groupName == 'StockTrade Future') {
      mappedGroupName = 'future';
    } else {
      mappedGroupName = widget.groupName.toLowerCase();
    }
    await sendJoinRequest(mappedGroupName, widget.type);
    setState(() {
      requested = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: widget.groupColor,
        title: Text('Join ${widget.groupName}'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, color: widget.groupColor, size: 80),
            const SizedBox(height: 24),
            Text(
              'Request to join "${widget.groupName}"',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              requested
                  ? 'Your request has been sent. Please wait for admin approval.'
                  : 'You need to request access to join this group.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            if (!requested)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.groupColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _requestJoin,
                child: const Text(
                  'Request Access',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
