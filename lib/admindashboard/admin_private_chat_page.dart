import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For timestamp formatting

class AdminPrivateChatPage extends StatefulWidget {
  final String userId;
  final String userName;
  final String userEmail;

  const AdminPrivateChatPage({
    super.key,
    required this.userId,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<AdminPrivateChatPage> createState() => _AdminPrivateChatPageState();
}

class _AdminPrivateChatPageState extends State<AdminPrivateChatPage> {
  final TextEditingController _controller = TextEditingController();
  final String adminId = 'admin';

  // SIMPLIFIED QUERY - NO INDEX REQUIRED
  Stream<QuerySnapshot> get _chatStream => FirebaseFirestore.instance
      .collection('groups')
      .doc('admin_chat')
      .collection('messages')
      .orderBy('timestamp', descending: false) // Simple ordering only
      .snapshots();

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    await FirebaseFirestore.instance
        .collection('groups')
        .doc('admin_chat')
        .collection('messages')
        .add({
      'text': text.trim(),
      'senderId': adminId,
      'senderName': 'Admin',
      'senderEmail': '',
      'recipientId': widget.userId,
      'recipientName': widget.userName,
      'recipientEmail': widget.userEmail,
      'timestamp': FieldValue.serverTimestamp(),
      'private': true,
      'participants': [adminId, widget.userId],
    });

    _controller.clear();
  }

  Future<void> _editMessage(String messageId, String newText) async {
    await FirebaseFirestore.instance
        .collection('groups')
        .doc('admin_chat')
        .collection('messages')
        .doc(messageId)
        .update({
      'text': newText,
      'edited': true,
    });
  }

  Future<void> _deleteMessage(String messageId) async {
    await FirebaseFirestore.instance
        .collection('groups')
        .doc('admin_chat')
        .collection('messages')
        .doc(messageId)
        .delete();
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
    return DateFormat('hh:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFFFE0B2),
              child: Icon(Icons.person, color: Colors.orange),
            ),
            const SizedBox(width: 12),
            Text(
              widget.userName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFF6F8FB),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // FILTER MESSAGES IN CODE INSTEAD OF QUERY (NO INDEX NEEDED)
                final messages = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final participants = List<String>.from(data['participants'] ?? []);
                  final isPrivate = data['private'] == true;
                  return isPrivate && participants.contains(widget.userId);
                }).toList();

                if (messages.isEmpty) {
                  return const Center(child: Text('No messages yet.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final data = msg.data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == adminId;
                    final senderName = data['senderName'] ?? '';
                    final text = data['text'] ?? '';
                    final messageId = msg.id;
                    final edited = data['edited'] == true;
                    final timestamp = data['timestamp'] as Timestamp?;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: GestureDetector(
                        onLongPress: isMe
                            ? () async {
                                final action = await showMenu<String>(
                                  context: context,
                                  position: RelativeRect.fromLTRB(200, 200, 100, 100),
                                  items: [
                                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                  ],
                                );
                                if (action == 'edit') {
                                  _showEditDialog(messageId, text);
                                } else if (action == 'delete') {
                                  await _deleteMessage(messageId);
                                }
                              }
                            : null,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.orange[100] : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    senderName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isMe ? Colors.orange : Colors.deepPurple,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _formatTimestamp(timestamp),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(text, style: const TextStyle(fontSize: 16)),
                              if (edited)
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Text(
                                    '(edited)',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.orange),
                  onPressed: () => _sendMessage(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
