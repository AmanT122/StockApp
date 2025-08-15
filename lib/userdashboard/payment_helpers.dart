// File path: lib/userdashboard/payment_helpers.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../messages/messages_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 🔧 UPI Launch Function - Direct Google Pay with Payment Verification
Future<void> launchUPI(
  BuildContext context, {
  required String payeeVPA,
  required String payeeName,
  required String amount,
  required String transactionNote,
  required String planType,
}) async {
  try {
    // Generate unique transaction ID
    final transactionId = 'TXN 2${DateTime.now().millisecondsSinceEpoch}';

    // Create UPI URL for Google Pay with transaction ID
    final upiUrl =
        'upi://pay?pa=$payeeVPA&pn=$payeeName&am=$amount&cu=INR&tn=$transactionNote&tr=$transactionId';
    final uri = Uri.parse(upiUrl);

    // Show payment instructions first
    await _showPaymentInstructions(context, amount, planType, transactionId);

    // Try to open Google Pay
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Opening Google Pay for payment...')),
      );

      // Wait for user to complete payment
      await Future.delayed(const Duration(seconds: 3));
      await _showPaymentVerificationDialog(
        context,
        amount,
        planType,
        transactionId,
      );
    } catch (e) {
      // Fallback: try alternative UPI apps
      await _showUPIAppSelection(
        context,
        payeeVPA,
        payeeName,
        amount,
        transactionNote,
        transactionId,
        planType,
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Error: $e')));
  }
}

// 🔧 Show Payment Instructions
Future<void> _showPaymentInstructions(
  BuildContext context,
  String amount,
  String planType,
  String transactionId,
) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Payment Instructions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: 2$amount'),
            Text('Plan: $planType'),
            Text('Transaction ID: $transactionId'),
            const SizedBox(height: 16),
            const Text(
              'Please complete the payment in Google Pay and then return to this app.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Important: Keep this transaction ID for verification.',
              style: TextStyle(color: Colors.orange),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Proceed'),
          ),
        ],
      );
    },
  );
}

// 🔧 Show UPI App Selection
Future<void> _showUPIAppSelection(
  BuildContext context,
  String payeeVPA,
  String payeeName,
  String amount,
  String transactionNote,
  String transactionId,
  String planType,
) async {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Select Payment App'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.payment),
              title: const Text('Google Pay'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final googlePayUri = Uri.parse(
                    'com.google.android.apps.nbu.paisa.user://',
                  );
                  await launchUrl(
                    googlePayUri,
                    mode: LaunchMode.externalApplication,
                  );
                  await Future.delayed(const Duration(seconds: 3));
                  await _showPaymentVerificationDialog(
                    context,
                    amount,
                    planType,
                    transactionId,
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not open Google Pay')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.payment),
              title: const Text('PhonePe'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final phonePeUri = Uri.parse(
                    'phonepe://pay?pa=$payeeVPA&pn=$payeeName&am=$amount&cu=INR&tn=$transactionNote&tr=$transactionId',
                  );
                  await launchUrl(
                    phonePeUri,
                    mode: LaunchMode.externalApplication,
                  );
                  await Future.delayed(const Duration(seconds: 3));
                  await _showPaymentVerificationDialog(
                    context,
                    amount,
                    planType,
                    transactionId,
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not open PhonePe')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.payment),
              title: const Text('Paytm'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final paytmUri = Uri.parse(
                    'paytmmp://pay?pa=$payeeVPA&pn=$payeeName&am=$amount&cu=INR&tn=$transactionNote&tr=$transactionId',
                  );
                  await launchUrl(
                    paytmUri,
                    mode: LaunchMode.externalApplication,
                  );
                  await Future.delayed(const Duration(seconds: 3));
                  await _showPaymentVerificationDialog(
                    context,
                    amount,
                    planType,
                    transactionId,
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not open Paytm')),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      );
    },
  );
}

// 🔧 Payment Verification Dialog with Enhanced Security
Future<void> _showPaymentVerificationDialog(
  BuildContext context,
  String amount,
  String planType,
  String transactionId,
) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Payment Verification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: 2$amount'),
            Text('Plan: $planType'),
            Text('Transaction ID: $transactionId'),
            const SizedBox(height: 16),
            const Text(
              'Please verify your payment:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('1. Check your payment app for confirmation'),
            const Text('2. Verify the transaction ID matches'),
            const Text('3. Ensure payment status is "Success"'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: const Text(
                ' 20 Only confirm if payment is actually successful',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Payment Failed'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              Navigator.of(context).pop();
              await _handlePaymentSuccess(
                context,
                amount,
                planType,
                transactionId,
              );
            },
            child: const Text('Payment Successful'),
          ),
        ],
      );
    },
  );
}

// 🔧 Handle Basic Plan Join (Free)
Future<void> _handleBasicPlanJoin(BuildContext context) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not logged in. Please login again.'),
        ),
      );
      return;
    }

    // Get user data
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final userData = userDoc.data();
    final userName = userData?['name'] ?? 'User';

    // Check if user is already in Future group
    final existingMember = await FirebaseFirestore.instance
        .collection('groups')
        .doc('Future')
        .collection('members')
        .doc(user.uid)
        .get();

    if (existingMember.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are already a member of the Future group!'),
        ),
      );
      return;
    }

    // Auto join Future group
    await FirebaseFirestore.instance
        .collection('groups')
        .doc('Future')
        .collection('members')
        .doc(user.uid)
        .set({
          'userId': user.uid,
          'userName': userName,
          'joinedAt': FieldValue.serverTimestamp(),
          'planType': 'Basic Plan (Free)',
          'paymentAmount': 0.0,
          'status': 'active',
        });

    // Send notification to admin
    await FirebaseFirestore.instance.collection('admin_notifications').add({
      'type': 'new_basic_member',
      'userId': user.uid,
      'userName': userName,
      'planType': 'Basic Plan (Free)',
      'amount': 0.0,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
      'message': '$userName has joined the Future group with Basic Plan (Free)',
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Successfully joined the Future group!'),
        backgroundColor: Colors.green,
      ),
    );

    // Navigate to messages page to show the group
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const MessagesPage()));
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error joining group: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// 🔧 Handle Payment Success and Auto Join Group
Future<void> _handlePaymentSuccess(
  BuildContext context,
  String amount,
  String planType,
  String transactionId,
) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not logged in. Please login again.'),
        ),
      );
      return;
    }

    // Get user data
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final userData = userDoc.data();
    final userName = userData?['name'] ?? 'User';

    // Create payment record with transaction ID
    await FirebaseFirestore.instance.collection('payments').add({
      'userId': user.uid,
      'userName': userName,
      'amount': double.parse(amount),
      'planType': planType,
      'status': 'completed',
      'timestamp': FieldValue.serverTimestamp(),
      'upiId': 'jaydarji1977@oksbi',
      'transactionId': transactionId,
      'verificationStatus': 'pending_admin_verification',
    });

    // Create pending membership (will be activated after admin verification)
    await FirebaseFirestore.instance
        .collection('groups')
        .doc('StockTrade')
        .collection('members')
        .doc(user.uid)
        .set({
          'userId': user.uid,
          'userName': userName,
          'joinedAt': FieldValue.serverTimestamp(),
          'planType': planType,
          'paymentAmount': double.parse(amount),
          'status': 'pending_verification',
          'transactionId': transactionId,
        });

    // Send notification to admin for payment verification
    await FirebaseFirestore.instance.collection('admin_notifications').add({
      'type': 'payment_verification_required',
      'userId': user.uid,
      'userName': userName,
      'planType': planType,
      'amount': double.parse(amount),
      'transactionId': transactionId,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending_verification',
      'message':
          '$userName has made a payment of 2$amount for $planType. Transaction ID: $transactionId. Please verify the payment.',
    });

    // Show success message with verification notice
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Payment submitted! Transaction ID: $transactionId. Your access will be activated after admin verification.',
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 5),
      ),
    );

    // Navigate to messages page to show the group
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const MessagesPage()));
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error processing payment: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// Add this helper function
Future<bool> isUserInFreeGroup() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;

  final doc = await FirebaseFirestore.instance
      .collection('groups')
      .doc('StockTrade')
      .collection('members')
      .doc(user.uid)
      .get();

  return doc.exists;
}

Future<void> handleFreePlanJoin(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User not logged in. Please login again.')),
    );
    return;
  }

  final alreadyMember = await isUserInFreeGroup();
  if (alreadyMember) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Already a Member'),
        content: const Text('You are already a member of the Free group!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return;
  }

  // Not a member, show join dialog
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.group, size: 48, color: Colors.green),
            const SizedBox(height: 18),
            const Text(
              'Join Free Group',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Get access to the StockTrade Free group for market tips and analysis.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);

                  final userDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .get();
                  final userName = userDoc.data()?['name'] ?? 'User';
                  final userEmail = userDoc.data()?['email'] ?? '';

                  // ✅ Add request to admin panel
                  await FirebaseFirestore.instance.collection('requests').add({
                    'userId': user.uid,
                    'userName': userName,
                    'userEmail': userEmail,
                    'groupName': 'free',
                    'type': 'Basic Plan (Free)',
                    'status': 'pending',
                    'requestedAt': FieldValue.serverTimestamp(),
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Request submitted! Awaiting admin approval.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text(
                  'Join Now',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
