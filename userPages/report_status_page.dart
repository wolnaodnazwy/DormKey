import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';

class ReportStatusPage extends StatefulWidget {
  const ReportStatusPage({super.key});

  @override
  _ReportStatusPageState createState() => _ReportStatusPageState();
}


class _ReportStatusPageState extends State<ReportStatusPage> {
  String _searchQuery = "";
  String? _selectedStatus;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  Stream<List<Map<String, dynamic>>> _fetchUserReports() {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection('reports')
        .where('user', isEqualTo: userId)
        .orderBy(
          'timestamp',
          descending: true,
        )
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'documentId': doc.id,
                'reportId': data['reportId'] ?? "Unknown Report ID",
                'timestamp': (data['timestamp'] as Timestamp?)?.toDate(),
                'category': data['category'] ?? "Nieznana",
                'room': data['room'] ?? "Nieznane",
                'description': data['description'] ?? "Brak opisu",
                'images': data['images'] ?? [],
                'applicationStatusRef':
                    data['application_status'] as DocumentReference?,
              };
            }).toList());
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
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Status zgłoszeń"),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: const InputDecoration(
                  labelText: "Wyszukaj zgłoszenie",
                  hintText: "Wpisz numer zgłoszenia lub datę",
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
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
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
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
                stream: _fetchUserReports(),
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
                    final reportId =
                        (report['reportId'] as String).toLowerCase();
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

                      return FutureBuilder<String>(
                        future: _fetchApplicationStatus(statusRef),
                        builder: (context, statusSnapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          final status =
                              statusSnapshot.data ?? "Status nieznany";

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
      ),
    );
  }

  Future<void> _deleteReport(String documentId) async {
    await FirebaseFirestore.instance
        .collection('reports')
        .doc(documentId)
        .delete();
  }

  void showReportDetailsDialog(
      BuildContext context, Map<String, dynamic> report, String documentId) {
    final images = report['images'] as List<dynamic>? ?? [];
    final isDeletable = report['applicationStatusRef'] != null &&
        (report['applicationStatusRef'] as DocumentReference).id == 'status_0';

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
                        return Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Image.network(
                            imageUrl,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
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
                    if (isDeletable)
                      FilledButton.tonal(
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.errorContainer,
                        ),
                        onPressed: () async {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                backgroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                title: Text(
                                  "Potwierdzenie",
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                content: Text(
                                  "Czy na pewno chcesz usunąć to zgłoszenie? \n\n"
                                  "Ta operacja jest nieodwracalna i nie będzie można jej cofnąć.",
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                actionsAlignment:
                                    MainAxisAlignment.spaceBetween,
                                actions: [
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text("Anuluj"),
                                  ),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .errorContainer,
                                      foregroundColor: Theme.of(context)
                                          .colorScheme
                                          .onErrorContainer,
                                    ),
                                    onPressed: () async {
                                      await _deleteReport(documentId);
                                      Navigator.of(context).pop();
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text("Usuń"),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: Text(
                          "Usuń zgłoszenie",
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
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
    return Row(
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
