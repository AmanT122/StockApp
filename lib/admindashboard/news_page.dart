import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../authication/helpers/news_service.dart';

class NewsPage extends StatelessWidget {
  final bool isAdmin;
  const NewsPage({required this.isAdmin, super.key});

  void _showNewsDialog(BuildContext context, {String? id, String? title, String? content}) {
    final titleController = TextEditingController(text: title);
    final contentController = TextEditingController(text: content);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(id == null ? 'Add News' : 'Edit News'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              maxLength: 60,
            ),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: 'Content'),
              maxLines: 4,
              maxLength: 500,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty || contentController.text.trim().isEmpty) return;
              if (id == null) {
                await NewsService.addNews(titleController.text.trim(), contentController.text.trim());
              } else {
                await NewsService.updateNews(id, titleController.text.trim(), contentController.text.trim());
              }
              Navigator.pop(context);
            },
            child: Text(id == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete News'),
        content: const Text('Are you sure you want to delete this news item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await NewsService.deleteNews(id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('News'),
        backgroundColor: isAdmin ? Colors.deepPurple : null,
        actions: [
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Chip(
                  label: const Text('Admin', style: TextStyle(color: Colors.white)),
                  backgroundColor: Colors.orange,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showNewsDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add News'),
              backgroundColor: Colors.deepPurple,
            )
          : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: NewsService.getNewsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final newsDocs = snapshot.data?.docs ?? [];
          if (newsDocs.isEmpty) {
            return const Center(child: Text('No news yet.'));
          }
          return ListView.builder(
            itemCount: newsDocs.length,
            itemBuilder: (context, index) {
              final news = newsDocs[index];
              DateTime? dateTime;
              if (news['timestamp'] != null) {
                final ts = news['timestamp'];
                if (ts is Timestamp) {
                  dateTime = ts.toDate();
                } else if (ts is DateTime) {
                  dateTime = ts;
                }
              }
              String dateStr = dateTime != null
                  ? '${dateTime.day.toString().padLeft(2, '0')} '
                    '${_monthName(dateTime.month)} '
                    '${dateTime.year}, '
                    '${_formatHourMinute(dateTime)}'
                  : '';
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  color: const Color(0xFFF8FAFC),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              news['title'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1f4037),
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              news['content'],
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                height: 1.4,
                              ),
                            ),
                            if (dateStr.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                dateStr,
                                style: const TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                            ],
                          ],
                        ),
                        if (isAdmin)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                  onPressed: () => _showNewsDialog(
                                    context,
                                    id: news.id,
                                    title: news['title'],
                                    content: news['content'],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                                  onPressed: () => _confirmDelete(context, news.id),
                                ),
                              ],
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
    );
  }

  String _monthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }

  String _formatHourMinute(DateTime dt) {
    int hour = dt.hour;
    final ampm = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $ampm';
  }
}