import 'package:firebase_test/widgets/full_screen_image_view.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';

class AllReportsPage extends StatefulWidget {
  const AllReportsPage({super.key});

  @override
  _AllReportsPageState createState() => _AllReportsPageState();
}

class _AllReportsPageState extends State<AllReportsPage> {
  String _searchQuery = "";
  String? _selectedStatus;
  final TextEditingController _searchController = TextEditingController();

  Stream<List<Map<String, dynamic>>> _fetchAllReports() {
    return FirebaseFirestore.instance
        .collection('reports')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> reports = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        String authorName = "Anonim";
        bool isAnonymous = data['isAnonymous'] ?? true;

        if (!isAnonymous && data['user'] != null) {
          try {
            final userId = data['user'];
            final user = await FirebaseFirestore.instance
                .collection('user_statuses')
                .doc(userId)
                .get();

            authorName = user.exists && user.data()?['displayName'] != null
                ? user.data()!['displayName']
                : "Nieznany użytkownik";
          } catch (e) {
            debugPrint("Error fetching user name for ID ${data['user']}: $e");
          }
        }

        reports.add({
          'documentId': doc.id,
          'reportId': data['reportId'] ?? "Unknown Report ID",
          'timestamp': (data['timestamp'] as Timestamp?)?.toDate(),
          'category': data['category'] ?? "Nieznana",
          'room': data['room'] ?? "Nieznane",
          'description': data['description'] ?? "Brak opisu",
          'images': data['images'] ?? [],
          'applicationStatusRef':
              data['application_status'] as DocumentReference?,
          'authorName': authorName,
        });
      }
      return reports;
    });
  }

  Future<List<Map<String, String>>> _fetchAllStatuses() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('application_status').get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'] as String,
      };
    }).toList();
  }

  Future<String> _fetchApplicationStatus(DocumentReference? statusRef) async {
    if (statusRef == null) return "Status nieznany";

    try {
      final doc = await statusRef.get();
      final data = doc.data() as Map<String, dynamic>?;
      return data?['name'] ?? "Status nieznany";
    } catch (e) {
      return "Status nieznany";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(32.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Wyszukaj zgłoszenie",
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          FutureBuilder<List<Map<String, String>>>(
            future: _fetchAllStatuses(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text("Brak dostępnych statusów"),
                );
              }
              final statuses = snapshot.data!;
              return Wrap(
                spacing: 8.0,
                children: statuses.map((status) {
                  final isSelected = _selectedStatus == status['id'];

                  return ChoiceChip(
                    label: Text(status['name']!,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.onSurface,
                            )),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedStatus = selected ? status['id'] : null;
                      });
                    },
                    selectedColor: Theme.of(context).colorScheme.primary,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _fetchAllReports(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      "Brak zgłoszeń",
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  );
                }

                final reports = snapshot.data!.where((report) {
                  final reportId = (report['reportId'] as String).toLowerCase();
                  final authorName =
                      (report['authorName'] as String).toLowerCase();

                  final timestamp = report['timestamp'] as DateTime?;
                  final formattedDate = timestamp != null
                      ? "${timestamp.day.toString().padLeft(2, '0')}.${timestamp.month.toString().padLeft(2, '0')}.${timestamp.year}"
                      : "";
                  final statusRef =
                      report['applicationStatusRef'] as DocumentReference?;
                  final statusId = statusRef?.id ?? "";

                  return (_selectedStatus == null ||
                          _selectedStatus == statusId) &&
                      (reportId.contains(_searchQuery) ||
                          authorName.contains(_searchQuery) ||
                          formattedDate.contains(_searchQuery));
                }).toList();

                if (reports.isEmpty) {
                  return Center(
                    child: Text(
                      "Nie znaleziono wyników",
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: reports.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    final reportId =
                        report['reportId'] ?? "Nieznany numer zgłoszenia";
                    final timestamp = report['timestamp'] as DateTime?;
                    final statusRef =
                        report['applicationStatusRef'] as DocumentReference?;

                    final formattedDate = timestamp != null
                        ? "${timestamp.day.toString().padLeft(2, '0')}.${timestamp.month.toString().padLeft(2, '0')}.${timestamp.year}"
                        : "Brak daty";
                    final authorName = report['authorName'];

                    return FutureBuilder<String>(
                      future: _fetchApplicationStatus(statusRef),
                      builder: (context, statusSnapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        final status = statusSnapshot.data ?? "Status nieznany";
                        return ListTile(
                          title: Text(
                            "Zgłoszenie nr $reportId",
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                status,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              Text(
                                "Data zgłoszenia: $formattedDate",
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Text(
                                "Zgłosił: $authorName",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          onTap: () => showReportDetailsDialog(
                            context,
                            report,
                            report['documentId'],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void showReportDetailsDialog(
      BuildContext context, Map<String, dynamic> report, String documentId) {
    final images = report['images'] as List<dynamic>? ?? [];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: context.containerDecoration,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.report, size: 28),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Zgłoszenie nr: ${report['reportId']}",
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDetailRow(context, "Kategoria", report['category']),
                const SizedBox(height: 8),
                _buildDetailRow(context, "Pomieszczenie", report['room']),
                const Divider(height: 32),
                Text(
                  "Opis:",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  report['description'] ?? 'Brak opisu',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.justify,
                ),
                if (images.isNotEmpty) ...[
                  const Divider(height: 24),
                  Text(
                    "Zdjęcia:",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        final imageUrl = images[index] as String;
                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => FullScreenImageView(
                                  imageUrls: images.cast<String>(),
                                  initialIndex: index,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Image.network(
                              imageUrl,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            DocumentReference? newStatusRef;
                            return StatefulBuilder(
                              builder: (context, setState) {
                                return AlertDialog(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.onPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: Text(
                                    "Zmień status",
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall,
                                  ),
                                  content: FutureBuilder<QuerySnapshot>(
                                    future: FirebaseFirestore.instance
                                        .collection('application_status')
                                        .get(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const CircularProgressIndicator();
                                      }
                                      if (!snapshot.hasData ||
                                          snapshot.data!.docs.isEmpty) {
                                        return const Text(
                                            "Brak dostępnych statusów.");
                                      }

                                      final statuses = snapshot.data!.docs;

                                      return Container(
                                        decoration: context.containerDecoration
                                            .copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .surface,
                                                border: Border.all(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .outline,
                                                    width: 1)),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<
                                                DocumentReference>(
                                              dropdownColor: Theme.of(context)
                                                  .colorScheme
                                                  .surface,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurface,
                                                  ),
                                              isExpanded: true,
                                              value: newStatusRef ??
                                                  report[
                                                      'applicationStatusRef'],
                                              items: statuses.map((doc) {
                                                return DropdownMenuItem<
                                                    DocumentReference>(
                                                  value: doc.reference,
                                                  child: Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 8.0),
                                                    child: Text(
                                                      doc['name'],
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyLarge,
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                              onChanged: (value) {
                                                setState(() {
                                                  newStatusRef = value!;
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  actions: [
                                    OutlinedButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text("Zamknij"),
                                    ),
                                    FilledButton(
                                      onPressed: () async {
                                        if (newStatusRef != null) {
                                          await FirebaseFirestore.instance
                                              .collection('reports')
                                              .doc(documentId)
                                              .update({
                                            'application_status': newStatusRef,
                                          });

                                          Navigator.of(context).pop();
                                        }
                                      },
                                      child: const Text("Zapisz"),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      },
                      child: Text(
                        "Zmień status",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("Zamknij"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Expanded(
            child: Text(
              value ?? "Nieznane",
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.justify,
              maxLines: null,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }
}
