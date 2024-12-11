import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_test/widgets/full_screen_image_view.dart';
import 'package:flutter/material.dart';
import 'package:firebase_test/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  final String id;
  final String title;
  final String content;
  final DateTime date;
  final String authorName;
  final List<String> images;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.authorName,
    required this.images,
  });

  factory Announcement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Announcement(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      authorName: data['authorName'] ?? '',
      images: List<String>.from(data['images'] ?? []),
    );
  }
}

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  late final String userId = FirebaseAuth.instance.currentUser?.uid ?? "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('announcements')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Wystąpił błąd: ${snapshot.error}'),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Brak dostępnych ogłoszeń'),
            );
          }
          final announcements = snapshot.data!.docs
              .map((doc) => Announcement.fromFirestore(doc))
              .toList();

          return StreamBuilder<Map<String, dynamic>>(
            stream: _userReadStatusStream(),
            builder: (context, readStatusSnapshot) {
              if (readStatusSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final readStatuses = readStatusSnapshot.data ?? {};

              return ListView.builder(
                padding:
                    const EdgeInsets.symmetric(vertical: 22, horizontal: 24),
                itemCount: announcements.length,
                itemBuilder: (context, index) {
                  final announcement = announcements[index];
                  final isRead = readStatuses[announcement.id] == true;

                  return GestureDetector(
                    onTap: () => _showAnnouncementDialog(context, announcement),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      padding: const EdgeInsets.all(12),
                      decoration: context.containerDecoration,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Text(
                              announcement.authorName
                                  .split(' ')
                                  .map((e) => e[0])
                                  .take(2)
                                  .join()
                                  .toUpperCase(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "${_formatDate(announcement.date)}, ${_formatTime(announcement.date)}",
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                    if (!isRead)
                                      const Icon(Icons.circle,
                                          color: Colors.red, size: 12),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  announcement.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  announcement.content,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ],
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

  Stream<Map<String, dynamic>> _userReadStatusStream() {
    return FirebaseFirestore.instance
        .collection('user_reads')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.data() ?? {});
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}";
  }

  String _formatTime(DateTime date) {
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  // Mark as read and show the dialog
  void _showAnnouncementDialog(
      BuildContext context, Announcement announcement) async {
    await _markAsRead(announcement.id);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: context.containerDecoration,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  announcement.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  announcement.authorName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  "${_formatDate(announcement.date)}, ${_formatTime(announcement.date)}",
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const Divider(height: 24),
                Text(
                  announcement.content,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.justify,
                ),
                if (announcement.images.isNotEmpty) ...[
                  const Divider(height: 24),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: announcement.images.length,
                      itemBuilder: (context, index) {
                        final imageUrl = announcement.images[index];
                        return Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FullScreenImageView(
                                    imageUrls:
                                        announcement.images.cast<String>(),
                                    initialIndex: index,
                                  ),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                imageUrl,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 100,
                                    height: 100,
                                    color: Colors.grey.shade300,
                                    child: const Icon(
                                      Icons.broken_image,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("Zamknij"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _markAsRead(String announcementId) async {
    try {
      await FirebaseFirestore.instance
          .collection('user_reads')
          .doc(userId)
          .set({announcementId: true}, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Failed to mark announcement as read: $e");
    }
  }
}
