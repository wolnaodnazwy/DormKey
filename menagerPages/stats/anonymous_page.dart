import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_test/menagerPages/stats/file_generator.dart';
import 'dart:async';

import 'package:intl/intl.dart';

class AnonymousPage extends StatefulWidget {
  const AnonymousPage({super.key});

  @override
  State<AnonymousPage> createState() => _AnonymousPageState();
}

class _AnonymousPageState extends State<AnonymousPage> {
  String _selectedTimeRange = "Ostatni miesiąc";
  Map<String, Map<String, double>> _reportData = {};
  late StreamSubscription<QuerySnapshot> _firestoreSubscription;
  DateTime now = DateTime.now();
  DateTime startDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _startFirestoreListener();
  }

  @override
  void dispose() {
    _firestoreSubscription.cancel();
    super.dispose();
  }

  void _startFirestoreListener() {
    DateTime now = DateTime.now();
    DateTime startDate;

    switch (_selectedTimeRange) {
      case "Ostatni tydzień":
        startDate = now.subtract(const Duration(days: 7));
        break;
      case "Ostatni miesiąc":
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case "Ostatni semestr":
        startDate = DateTime(now.year, now.month - 6, now.day);
        break;
      case "Ostatni rok":
        startDate = DateTime(now.year - 1, now.month, now.day);
        break;
      default:
        startDate = now.subtract(const Duration(days: 30));
    }

    _firestoreSubscription = FirebaseFirestore.instance
        .collection('reports')
        .where('timestamp', isGreaterThanOrEqualTo: startDate)
        .where('timestamp', isLessThanOrEqualTo: now)
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      Map<String, double> anonymousCounts = {};
      Map<String, double> totalCounts = {};

      for (var doc in snapshot.docs) {
        String category = doc['category'] as String;
        bool isAnonymous = doc['isAnonymous'] as bool;

        totalCounts[category] = (totalCounts[category] ?? 0) + 1;
        if (isAnonymous) {
          anonymousCounts[category] = (anonymousCounts[category] ?? 0) + 1;
        }
      }

      Map<String, Map<String, double>> data = {};
      for (var category in totalCounts.keys) {
        double anonymousCount = anonymousCounts[category] ?? 0;
        double totalCount = totalCounts[category]!;
        double nonAnonymousCount = totalCount - anonymousCount;

        data[category] = {
          "Anonimowe": (anonymousCount / totalCount) * 100,
          "Nieanonimowe": (nonAnonymousCount / totalCount) * 100,
        };
      }

      final sortedData = Map.fromEntries(
        data.entries.toList()
          ..sort(
              (a, b) => b.value["Anonimowe"]!.compareTo(a.value["Anonimowe"]!)),
      );

      setState(() {
        _reportData = sortedData;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final String formattedStartDate =
        DateFormat('yyyy-MM-dd').format(startDate);
    final String formattedEndDate = DateFormat('yyyy-MM-dd').format(now);

    List<List<String>> exportData = [
      ["Zakres danych", "od $formattedStartDate do $formattedEndDate"],
      ["Kategoria", "Anonimowe", "Nieanonimowe"],
      ..._reportData.entries.map(
        (entry) => [
          entry.key,
          (entry.value["Anonimowe"] ?? 0).toStringAsFixed(1),
          (entry.value["Nieanonimowe"] ?? 0).toStringAsFixed(1),
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Zgłoszenia anonimowe"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              "Proporcje zgłoszeń anonimowych",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Zakres danych:",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                DropdownButton<String>(
                  value: _selectedTimeRange,
                  onChanged: (value) {
                    setState(() {
                      _selectedTimeRange = value!;
                      _firestoreSubscription.cancel();
                      _startFirestoreListener();
                    });
                  },
                  items: [
                    "Ostatni tydzień",
                    "Ostatni miesiąc",
                    "Ostatni semestr",
                    "Ostatni rok"
                  ]
                      .map((String range) => DropdownMenuItem(
                            value: range,
                            child: Text(range),
                          ))
                      .toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _reportData.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      children: _reportData.entries.map((entry) {
                        final category = entry.key;
                        final anonymousPercentage =
                            entry.value["Anonimowe"] ?? 0;
                        final nonAnonymousPercentage =
                            entry.value["Nieanonimowe"] ?? 0;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  flex: anonymousPercentage.toInt(),
                                  child: Container(
                                    height: 20,
                                    color: Colors.orange,
                                  ),
                                ),
                                Expanded(
                                  flex: nonAnonymousPercentage.toInt(),
                                  child: Container(
                                    height: 20,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                    "Anonimowe: ${anonymousPercentage.toStringAsFixed(1)}%"),
                                Text(
                                    "Nieanonimowe: ${nonAnonymousPercentage.toStringAsFixed(1)}%"),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      }).toList(),
                    ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => generateCSV(
                    data: exportData,
                    fileName: "anonimowe_zgloszenia",
                    context: context,
                  ),
                  child: const Text("Eksportuj CSV"),
                ),
                ElevatedButton(
                  onPressed: () => generatePDF(
                    data: exportData,
                    fileName: "anonimowe_zgloszenia",
                    context: context,
                  ),
                  child: const Text("Eksportuj PDF"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
