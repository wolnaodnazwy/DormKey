import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_test/menagerPages/stats/file_generator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  String _selectedTimeRange = "Ostatni miesiąc";
  Map<String, double> _reportData = {};
  DateTime now = DateTime.now();
  DateTime startDate = DateTime.now();
  final List<Color> _baseColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.grey,
    Colors.red,
    Colors.cyan,
    Colors.pink,
    Colors.teal,
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    now = DateTime.now();
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

    Map<String, double> categoryCounts = {};
    for (var doc in reports.docs) {
      String category = doc['category'] as String;
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
    }

    double total = categoryCounts.values.fold(0, (sum, count) => sum + count);
    List<MapEntry<String, double>> sortedData = categoryCounts.entries
        .map((entry) => MapEntry(entry.key, (entry.value / total) * 100))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    setState(() {
      _reportData = Map.fromEntries(sortedData);
    });
  }

  Color _getCategoryColor(int index) {
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
      ["Kategoria", "Procent"],
      ..._reportData.entries
          .map((entry) => [entry.key, "${entry.value.toInt()}%"]),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kategorie zgłoszeń"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Podział zgłoszeń według kategorii",
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
              child: _reportData.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : PieChart(
                      PieChartData(
                        sections: _reportData.entries.map((entry) {
                          final color = _getCategoryColor(
                              _reportData.keys.toList().indexOf(entry.key));
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
                itemCount: _reportData.keys.length,
                itemBuilder: (context, index) {
                  final category = _reportData.keys.elementAt(index);
                  final color = _getCategoryColor(index);
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color,
                      radius: 10,
                    ),
                    title: Text(category),
                    trailing: Text(
                      "${_reportData[category]!.toInt()}%",
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
                    fileName: "kategorie_zgloszen",
                    context: context,
                  ),
                  child: const Text("Eksportuj CSV"),
                ),
                ElevatedButton(
                  onPressed: () => generatePDF(
                    data: exportData,
                    fileName: "kategorie_zgloszen",
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
