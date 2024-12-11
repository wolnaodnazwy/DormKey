import 'package:flutter/material.dart';

class ReservationListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> reservations;
  final String reservationType;

  const ReservationListWidget({
    super.key,
    required this.reservations,
    required this.reservationType,
  });

  @override
  Widget build(BuildContext context) {
    return reservations.isEmpty
        ? const Center(child: Text("Brak rezerwacji na ten dzień."))
        : ListView.separated(
            itemCount: reservations.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final reservation = reservations[index];
              final startTime = reservation['start_time'];
              final endTime = reservation['end_time'];

              final startDateFormatted =
                  "${startTime.day}.${startTime.month}";
              final endDateFormatted =
                  "${endTime.day}.${endTime.month}";
              final startTimeFormatted =
                  "${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}";
              final endTimeFormatted =
                  "${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}";

              if (reservationType == 'room') {
                final room = reservation['resource_id'];
                return ListTile(
                  title: Text(
                    '$room',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  subtitle: Text(
                    "Od: $startDateFormatted, $startTimeFormatted\n"
                    "Do: $endDateFormatted, $endTimeFormatted",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              } else {
                final washerCount =
                    (reservation['resource_id'] as List).length;
                return ListTile(
                  title: Text(
                    'Liczba zajętych pralek: $washerCount',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  subtitle: Text(
                    "Od: $startDateFormatted, $startTimeFormatted\n"
                    "Do: $endDateFormatted, $endTimeFormatted",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              }
            },
          );
  }
}