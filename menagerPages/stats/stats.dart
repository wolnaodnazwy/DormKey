import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_test/main.dart';
import 'package:firebase_test/menagerPages/stats/anonymous_page.dart';
import 'package:firebase_test/menagerPages/stats/categories_page.dart';
import 'package:firebase_test/menagerPages/stats/file_generator.dart';
import 'package:firebase_test/menagerPages/stats/rooms_pages.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final List<Color> _baseColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.grey,
    Colors.purple,
    Colors.cyan,
    Colors.pink,
    Colors.brown,
    Colors.yellow,
    Colors.indigo,
    Colors.teal,
    Colors.amber,
    Colors.lime,
    Colors.deepOrange,
    Colors.lightBlue,
    Colors.deepPurple,
  ];
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 10.0,
          bottom: TabBar(
            indicatorColor: Theme.of(context).colorScheme.onPrimary,
            labelColor: Theme.of(context).colorScheme.onPrimary,
            unselectedLabelColor: Theme.of(context).colorScheme.onPrimary,
            labelStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            unselectedLabelStyle: Theme.of(context).textTheme.bodyMedium,
            tabs: const [
              Tab(text: "Zgłoszenia"),
              Tab(text: "Pochodzenie"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildReportsSection(),
            _buildOriginContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsSection() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          _buildStyledCard(
            title: "Kategorie",
            subtitle: "Zgłoszenia według kategorii",
            description: "Analiza usterek w podziale na kategorie.",
            icon: Icons.pie_chart,
            actionLabel: "Zobacz szczegóły",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CategoriesPage()),
              );
            },
          ),
          const SizedBox(height: 10),
          _buildStyledCard(
            title: "Pomieszczenia",
            subtitle: "Zgłoszenia według lokalizacji",
            description: "Przegląd najczęściej zgłaszanych pomieszczeń.",
            icon: Icons.meeting_room,
            actionLabel: "Zobacz szczegóły",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RoomsPage()),
              );
            },
          ),
          const SizedBox(height: 10),
          _buildStyledCard(
            title: "Anonimowe",
            subtitle: "Analiza anonimowości",
            description: "Proporcje anonimowych zgłoszeń w kategoriach.",
            icon: Icons.lock,
            actionLabel: "Zobacz szczegóły",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AnonymousPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStyledCard({
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: Theme.of(context).colorScheme.onPrimary,
        shape: context.cardDecorationShape,
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      icon,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            maxLines: 1,
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            subtitle,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.4,
                  child: TextButton(
                    onPressed: onTap,
                    style: TextButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    child: Text(
                      actionLabel,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOriginContent() {
    return FutureBuilder<Map<String, double>>(
      future: _fetchProvinceData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Wystąpił błąd: ${snapshot.error}"));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Brak danych do wyświetlenia."));
        }

        final data = snapshot.data!;
        final total = data.values.reduce((a, b) => a + b);
        final String formattedDate =
            DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

        final List<List<String>> exportData = [
          ["Raport wygenerowano", formattedDate],
          [],
          ["Wojewodztwo", "Liczba uzytkownikow", "Procent"],
          ...data.entries.map((entry) {
            final percentage = (entry.value / total * 100).toStringAsFixed(1);
            return [entry.key, entry.value.toStringAsFixed(0), "$percentage%"];
          }),
        ];

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Pochodzenie mieszkańców",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: PieChart(
                  PieChartData(
                    sections: data.entries.map((entry) {
                      final index = data.keys.toList().indexOf(entry.key);
                      final color = _baseColors[index % _baseColors.length];
                      final percentage =
                          (entry.value / total * 100).toStringAsFixed(1);

                      return PieChartSectionData(
                        color: color,
                        value: entry.value,
                        title: "$percentage%",
                        titleStyle: const TextStyle(
                          fontSize: 14,
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
                  itemCount: data.keys.length,
                  itemBuilder: (context, index) {
                    final province = data.keys.elementAt(index);
                    final color = _baseColors[index % _baseColors.length];
                    final percentage =
                        (data[province]! / total * 100).toStringAsFixed(1);

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color,
                        radius: 10,
                      ),
                      title: Text(province),
                      trailing: Text("$percentage%"),
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
                      fileName: "pochodzenie_mieszkancow",
                      context: context,
                    ),
                    child: const Text("Eksportuj CSV"),
                  ),
                  ElevatedButton(
                    onPressed: () => generatePDF(
                      data: exportData,
                      fileName: "pochodzenie_mieszkancow",
                      context: context,
                    ),
                    child: const Text("Eksportuj PDF"),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, double>> _fetchProvinceData() async {
    final users =
        await FirebaseFirestore.instance.collection('user_statuses').get();

    Map<String, double> provinceCounts = {};
    for (var doc in users.docs) {
      final province = doc.data()['province'] as String? ?? "Inne";
      provinceCounts[province] = (provinceCounts[province] ?? 0) + 1;
    }

    return provinceCounts;
  }
}