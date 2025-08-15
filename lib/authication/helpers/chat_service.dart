import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get chat collection name based on group type
  static String getChatCollection(String groupName) {
    if (groupName == 'Admin Chat') {
      final user = _auth.currentUser;
      return 'admin_chats/${user?.uid}/messages';
    }
    return 'group_chats/$groupName';
  }

  // Send message with enhanced features
  static Future<void> sendMessage({
    required String groupName,
    required String text,
    bool isAdmin = false,
  }) async {
    if (text.trim().isEmpty) return;

    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Get user data
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      final userName = userData?['name'] ?? 'User';

      // Create message document with unique ID
      final messageRef = _firestore
          .collection(getChatCollection(groupName))
          .doc();

      final messageData = {
        'text': text.trim(),
        'senderId': user.uid,
        'senderName': userName,
        'timestamp': FieldValue.serverTimestamp(),
        'isAdmin': isAdmin,
        'status': 'sent',
        'messageId': messageRef.id,
        'type': 'text', // For future media support
      };

      await messageRef.set(messageData);

      // Update message status to delivered after a short delay
      Future.delayed(const Duration(seconds: 1), () async {
        try {
          await messageRef.update({'status': 'delivered'});
        } catch (e) {
          // Ignore errors for status updates
        }
      });
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Get real-time message stream
  static Stream<QuerySnapshot> getMessageStream(String groupName) {
    return _firestore
        .collection(getChatCollection(groupName))
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Mark messages as read
  static Future<void> markMessagesAsRead(String groupName) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final messages = await _firestore
          .collection(getChatCollection(groupName))
          .where('senderId', isNotEqualTo: user.uid)
          .where('status', whereIn: ['sent', 'delivered'])
          .get();

      final batch = _firestore.batch();
      for (final doc in messages.docs) {
        batch.update(doc.reference, {'status': 'read'});
      }
      await batch.commit();
    } catch (e) {
      // Ignore errors for read status updates
    }
  }

  // Check if user is member of a group
  static Future<bool> isUserMember(String groupName) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    // Admin chat is always accessible
    if (groupName == 'Admin Chat') return true;

    final doc = await _firestore
        .collection('groups')
        .doc(groupName)
        .collection('members')
        .doc(user.uid)
        .get();
    return doc.exists;
  }

  // Get group members count
  static Future<int> getGroupMembersCount(String groupName) async {
    if (groupName == 'Admin Chat') return 1; // Individual chat

    final snapshot = await _firestore
        .collection('groups')
        .doc(groupName)
        .collection('members')
        .get();
    return snapshot.docs.length;
  }

  // Get last message for group preview
  static Future<Map<String, dynamic>?> getLastMessage(String groupName) async {
    try {
      final snapshot = await _firestore
          .collection(getChatCollection(groupName))
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Delete message (admin only)
  static Future<void> deleteMessage(String groupName, String messageId) async {
    try {
      await _firestore
          .collection(getChatCollection(groupName))
          .doc(messageId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  // Get typing status stream (for future typing indicators)
  static Stream<DocumentSnapshot> getTypingStatusStream(String groupName) {
    final user = _auth.currentUser;
    if (user == null) return Stream.empty();

    return _firestore
        .collection('typing_status')
        .doc('${groupName}_${user.uid}')
        .snapshots();
  }

  // Update typing status
  static Future<void> updateTypingStatus(
    String groupName,
    bool isTyping,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('typing_status')
          .doc('${groupName}_${user.uid}')
          .set({
            'isTyping': isTyping,
            'userId': user.uid,
            'timestamp': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      // Ignore typing status errors
    }
  }

  // Get unread message count
  static Future<int> getUnreadMessageCount(String groupName) async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    try {
      final snapshot = await _firestore
          .collection(getChatCollection(groupName))
          .where('senderId', isNotEqualTo: user.uid)
          .where('status', whereIn: ['sent', 'delivered'])
          .get();

      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // Send admin message to specific user
  static Future<void> sendAdminMessage({
    required String userId,
    required String text,
  }) async {
    try {
      final adminDoc = await _firestore
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .get();
      final adminData = adminDoc.data();
      final adminName = adminData?['name'] ?? 'Admin';

      final messageRef = _firestore.collection('admin_chats/$userId').doc();

      await messageRef.set({
        'text': text.trim(),
        'senderId': _auth.currentUser?.uid,
        'senderName': adminName,
        'timestamp': FieldValue.serverTimestamp(),
        'isAdmin': true,
        'status': 'sent',
        'messageId': messageRef.id,
        'type': 'text',
      });

      // Update to delivered
      Future.delayed(const Duration(seconds: 1), () async {
        try {
          await messageRef.update({'status': 'delivered'});
        } catch (e) {
          // Ignore errors
        }
      });
    } catch (e) {
      throw Exception('Failed to send admin message: $e');
    }
  }
}
