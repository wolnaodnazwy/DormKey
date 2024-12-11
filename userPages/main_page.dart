import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';
import 'my_reservations.dart';
import 'report_status_page.dart';

class StartCardPage extends StatelessWidget {
  const StartCardPage({super.key});

  Future<List<Map<String, dynamic>>> _fetchReportsForUser() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      debugPrint("No user ID found. Ensure the user is logged in.");
      return [];
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('reports')
          .where('user', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(3)
          .get();
      debugPrint(
          "Fetched ${snapshot.docs.length} reports for user ID: $userId");

      if (snapshot.docs.isEmpty) {
        debugPrint("No reports found for user ID: $userId");
        return [];
      }

      final List<Map<String, dynamic>> reports = [];

      for (var doc in snapshot.docs) {
        final reportId =
            doc.data()['reportId'] as String? ?? "Unknown Report ID";
        final applicationStatusRef =
            doc.data()['application_status'] as DocumentReference?;

        if (applicationStatusRef == null) {
          debugPrint(
              "Missing 'reportId' or 'application_status' for report: ${doc.id}");
          continue;
        }

        try {
          final applicationStatusDoc = await applicationStatusRef.get();
          final statusData =
              applicationStatusDoc.data() as Map<String, dynamic>?;

          if (statusData == null) {
            debugPrint(
                "Missing data in application_status document: ${applicationStatusRef.path}");
            continue;
          }

          final statusName = statusData['name'] as String? ?? "Unknown Status";

          reports.add({
            'reportId': reportId,
            'statusName': statusName,
          });
        } catch (e) {
          debugPrint(
            "Error fetching application_status for report ID: $reportId. Error: $e",
          );
        }
      }

      return reports;
    } catch (e) {
      debugPrint("Error fetching reports: $e");
      return [];
    }
  }

  Stream<List<Map<String, dynamic>>> _fetchUpcomingReservationsStream() {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      debugPrint("No user ID found. Ensure the user is logged in.");
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection('reservations')
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();

      final reservations = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'reservation_type': data['reservation_type'] ?? "Unknown",
          'start_time': (data['start_time'] as Timestamp).toDate(),
          'end_time': (data['end_time'] as Timestamp).toDate(),
          'resource_id': data['resource_id'],
        };
      }).where((reservation) {
        return reservation['start_time'].isAfter(now);
      }).toList();

      reservations.sort((a, b) =>
          (a['start_time'] as DateTime).compareTo(b['start_time'] as DateTime));

      return reservations.take(3).toList();
    });
  }

  Future<List<String>> _fetchResourceNames(
      dynamic resourceId, String type) async {
    try {
      if (type == 'room' && resourceId is DocumentReference) {
        debugPrint("Fetching room resource with ID: ${resourceId.path}");

        final doc = await resourceId.get();
        final data = doc.data() as Map<String, dynamic>?;

        return [data?['name'] ?? 'Nieznany zasób'];
      }

      if (type == 'washer' && resourceId is List) {
        final List<String> names = [];
        for (var ref in resourceId) {
          if (ref is DocumentReference) {
            final doc = await ref.get();
            final data = doc.data() as Map<String, dynamic>?;
            final name = data?['name'];
            if (name != null) names.add(name);
          }
        }
        return names.isNotEmpty ? names : ['Nieznany zasób'];
      }

      return ['Nieznany zasób'];
    } catch (e) {
      debugPrint("Error fetching resource names: $e");
      return ['Nieznany zasób'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 50,
              decoration: context.containerDecoration
                  .copyWith(color: Theme.of(context).colorScheme.primary),
              alignment: Alignment.center,
              child: FractionallySizedBox(
                widthFactor: 0.9,
                child: Text(
                  "Twoje najblizsze rezerwacje",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MyReservationsPage()),
                  );
                },
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _fetchUpcomingReservationsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          "Brak nadchodzących rezerwacji",
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      );
                    }

                    final reservations = snapshot.data!;
                    return ListView.separated(
                      itemCount: reservations.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final reservation = reservations[index];
                        final reservationType = reservation['reservation_type'];
                        final startTime = reservation['start_time'] as DateTime;
                        final endTime = reservation['end_time'] as DateTime;
                        final resourceId = reservation['resource_id'];

                        // Choose the correct icon
                        final icon = reservationType == "room"
                            ? Icons.meeting_room
                            : Icons.local_laundry_service;

                        // Format date and time
                        final dateFormatted =
                            "${startTime.day.toString().padLeft(2, '0')}.${startTime.month.toString().padLeft(2, '0')}.${startTime.year}";
                        final timeFormatted =
                            "${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')} - ${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}";

                        return FutureBuilder<List<String>>(
                          future:
                              _fetchResourceNames(resourceId, reservationType),
                          builder: (context, resourceSnapshot) {
                            if (resourceSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const ListTile(
                                title: Text("Ładowanie..."),
                              );
                            }

                            final resourceNames = resourceSnapshot.data ??
                                <String>['Nieznany zasób'];

                            return ListTile(
                              leading: Icon(
                                icon,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              title: Text(
                                "$dateFormatted, godzina $timeFormatted",
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              subtitle: Text(
                                resourceNames.join(", "),
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            Container(
              height: 50,
              decoration: context.containerDecoration
                  .copyWith(color: Theme.of(context).colorScheme.primary),
              alignment: Alignment.center,
              child: FractionallySizedBox(
                widthFactor: 0.9,
                child: Text(
                  "Status twoich zgłoszeń",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ReportStatusPage()),
                  );
                },
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchReportsForUser(),
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

                    final reports = snapshot.data!;
                    return ListView.separated(
                      itemCount: reports.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final report = reports[index];
                        final reportId = report['reportId'];
                        final statusName = report['statusName'];

                        return ListTile(
                          title: Text(
                            "Zgłoszenie nr $reportId",
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                          subtitle: Text(
                            statusName,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
