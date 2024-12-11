import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HoursPage extends StatefulWidget {
  const HoursPage({super.key});

  @override
  State<HoursPage> createState() => _HoursPageState();
}

class _HoursPageState extends State<HoursPage> {
  String _selectedTimeRange = "Ostatni miesiąc";
  DateTime now = DateTime.now();
  DateTime startDate = DateTime.now();
  Map<String, Map<String, dynamic>> roomData = {};
  Map<String, dynamic> washerData = {};

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

    QuerySnapshot reservations = await FirebaseFirestore.instance
        .collection('reservations')
        .where('start_time', isGreaterThanOrEqualTo: startDate)
        .where('start_time', isLessThanOrEqualTo: now)
        .get();

    Map<String, List<DateTime>> roomHours = {};
    Map<String, Map<String, int>> washerHours = {};

    for (var doc in reservations.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final startTime = (data['start_time'] as Timestamp).toDate();
      final endTime = (data['end_time'] as Timestamp).toDate();
      final reservationType = data['reservation_type'];

      if (reservationType == 'room') {
        final resourceId = data['resource_id'];
        roomHours[resourceId] ??= [];
        roomHours[resourceId]?.addAll(_getHoursRange(startTime, endTime));
      } else if (reservationType == 'washer') {
        final List<dynamic> washerIds = data['resource_id'];
        final hourRange = _getHoursRange(startTime, endTime);
        for (var hour in hourRange) {
          for (var washerId in washerIds) {
            washerHours[hour.toString()] ??= {};
            washerHours[hour.toString()]?[washerId] =
                (washerHours[hour.toString()]?[washerId] ?? 0) + 1;
          }
        }
      }
    }

    final roomSummary = await _summarizeRooms(roomHours);
    final washerSummary = _summarizeWashers(washerHours);

    setState(() {
      roomData = roomSummary;
      washerData = washerSummary;
    });
  }

  List<DateTime> _getHoursRange(DateTime start, DateTime end) {
    List<DateTime> hours = [];
    DateTime current = DateTime(start.year, start.month, start.day, start.hour);
    while (current.isBefore(end)) {
      hours.add(current);
      current = current.add(const Duration(hours: 1));
    }
    return hours;
  }

  Future<Map<String, Map<String, dynamic>>> _summarizeRooms(
      Map<String, List<DateTime>> roomHours) async {
    Map<String, Map<String, dynamic>> summary = {};
    for (var resourceId in roomHours.keys) {
      var counts = <DateTime, int>{};
      for (var hour in roomHours[resourceId]!) {
        counts[hour] = (counts[hour] ?? 0) + 1;
      }

      DateTime peakHour = counts.keys.reduce((a, b) => counts[a]! > counts[b]! ? a : b);

      final roomSnapshot = await FirebaseFirestore.instance
          .collection('rooms_for_reservation')
          .doc(resourceId)
          .get();
      final roomName = roomSnapshot['name'];

      summary[resourceId] = {
        'name': roomName,
        'peak_hour': peakHour,
        'reservations': counts[peakHour]!,
      };
    }
    return summary;
  }

  Map<String, dynamic> _summarizeWashers(Map<String, Map<String, int>> washerHours) {
    Map<String, int> hourTotals = {};

    for (var hour in washerHours.keys) {
      hourTotals[hour] = washerHours[hour]!.values.fold(0, (sum, count) => sum + count);
    }

    String peakHour = hourTotals.keys.reduce((a, b) => hourTotals[a]! > hourTotals[b]! ? a : b);

    return {
      'peak_hour': peakHour,
      'reservations': hourTotals[peakHour]!,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Godziny największego obciążenia"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 16),
            Text(
              "Pomieszczenia",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Expanded(
              child: ListView.builder(
                itemCount: roomData.keys.length,
                itemBuilder: (context, index) {
                  final room = roomData.values.elementAt(index);
                  return ListTile(
                    title: Text(room['name']),
                    subtitle: Text("Godzina: ${DateFormat('HH:mm').format(room['peak_hour'])}, Rezerwacje: ${room['reservations']}"),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Pralki",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (washerData.isNotEmpty)
              Text(
                "Godzina: ${washerData['peak_hour']}, Rezerwacje pralek: ${washerData['reservations']}",
                style: Theme.of(context).textTheme.bodyLarge,
              ),
          ],
        ),
      ),
    );
  }
}
