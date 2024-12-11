import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_test/menagerPages/stats/file_generator.dart';
import 'package:intl/intl.dart';

class RoomsPage extends StatefulWidget {
  const RoomsPage({super.key});

  @override
  State<RoomsPage> createState() => _RoomsPageState();
}

class _RoomsPageState extends State<RoomsPage> {
  String _selectedTimeRange = "Ostatni miesiąc";
  DateTime now = DateTime.now();
  DateTime startDate = DateTime.now();
  Map<String, double> _roomData = {};
  final List<Color> _baseColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.grey,
    Colors.purple,
    Colors.cyan,
    Colors.pink,
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    DateTime now = DateTime.now();

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

    QuerySnapshot reports = await FirebaseFirestore.instance
        .collection('reports')
        .where('timestamp', isGreaterThanOrEqualTo: startDate)
        .where('timestamp', isLessThanOrEqualTo: now)
        .get();

    Map<String, double> roomCounts = {};
    for (var doc in reports.docs) {
      String room = doc['room'] as String;
      roomCounts[room] = (roomCounts[room] ?? 0) + 1;
    }

    double total = roomCounts.values.fold(0, (sum, count) => sum + count);
    List<MapEntry<String, double>> sortedData = roomCounts.entries
        .map((entry) => MapEntry(entry.key, (entry.value / total) * 100))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    setState(() {
      _roomData = Map.fromEntries(sortedData);
    });
  }

  Color _getRoomColor(int index) {
    int baseColorIndex = index % _baseColors.length;
    double shadeFactor = 1 - (index ~/ _baseColors.length) * 0.2;
    shadeFactor = shadeFactor.clamp(0.4, 1.0);
    return _baseColors[baseColorIndex].withOpacity(shadeFactor);
  }

  @override
  Widget build(BuildContext context) {
    final String formattedStartDate =
        DateFormat('yyyy-MM-dd').format(startDate);
    final String formattedEndDate = DateFormat('yyyy-MM-dd').format(now);

    final List<List<String>> exportData = [
      ["Zakres danych", "od $formattedStartDate do $formattedEndDate"],
      [],
      ["Pomieszczenie", "Procent"],
      ..._roomData.entries
          .map((entry) => [entry.key, "${entry.value.toInt()}%"]),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Zgłaszane pomieszczenia"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Problematyczne pomieszczenia",
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
                      _fetchData();
                    });
                  },
                  items: [
                    "Ostatni tydzień",
                    "Ostatni miesiąc",
                    "Ostatni semestr",
                    "Ostatni rok"
                  ].map((String range) {
                    return DropdownMenuItem<String>(
                      value: range,
                      child: Text(range),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _roomData.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : PieChart(
                      PieChartData(
                        sections: _roomData.entries.map((entry) {
                          final color = _getRoomColor(
                              _roomData.keys.toList().indexOf(entry.key));
                          return PieChartSectionData(
                            color: color,
                            value: entry.value,
                            title: "${entry.value.toInt()}%",
                            titleStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _roomData.keys.length,
                itemBuilder: (context, index) {
                  final room = _roomData.keys.elementAt(index);
                  final color = _getRoomColor(index);
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color,
                      radius: 10,
                    ),
                    title: Text(room),
                    trailing: Text(
                      "${_roomData[room]!.toInt()}%",
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => generateCSV(
                    data: exportData,
                    fileName: "pomieszczenia_zgloszen",
                    context: context,
                  ),
                  child: const Text("Eksportuj CSV"),
                ),
                ElevatedButton(
                  onPressed: () => generatePDF(
                    data: exportData,
                    fileName: "pomieszczenia_zgloszen",
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
