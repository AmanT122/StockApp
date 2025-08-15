import 'package:cloud_firestore/cloud_firestore.dart';

class NewsService {
  static final _newsCollection = FirebaseFirestore.instance.collection('news');

  static Stream<QuerySnapshot> getNewsStream() =>
      _newsCollection.orderBy('timestamp', descending: true).snapshots();

  static Future<void> addNews(String title, String content) {
    return _newsCollection.add({
      'title': title,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateNews(String id, String title, String content) {
    return _newsCollection.doc(id).update({
      'title': title,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteNews(String id) {
    return _newsCollection.doc(id).delete();
  }
}
