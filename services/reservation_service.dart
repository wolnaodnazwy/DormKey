import 'package:cloud_firestore/cloud_firestore.dart';

class ReservationService {
  Future<String> fetchRoomName(DocumentReference? resourceRef) async {
    if (resourceRef == null) return 'Unknown Room';
    try {
      final roomSnapshot = await resourceRef.get();

      if (!roomSnapshot.exists) {
        return 'Unknown Room';
      }

      final roomData = roomSnapshot.data() as Map<String, dynamic>;
      return roomData['name'] ?? 'Unnamed Room';
    } catch (e) {
      return 'Error Fetching Name';
    }
  }

  Future<List<Map<String, dynamic>>> getRoomReservationsForDay(
      DateTime? selectedDate) async {
    if (selectedDate == null) return [];
    final startOfDay =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final endOfDay = DateTime(
        selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59);
    final query = FirebaseFirestore.instance
        .collection('reservations')
        .where('reservation_type', isEqualTo: 'room')
        .where('end_time',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('start_time', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay));
    final snapshot = await query.get();

    final Map<String, Map<String, dynamic>> reservations = {};
    for (var doc in snapshot.docs) {
      final resourceRef = doc['resource_id'] as DocumentReference?;
      final roomName = await fetchRoomName(resourceRef);
      reservations[doc.id] = {
        'start_time': (doc['start_time'] as Timestamp).toDate(),
        'end_time': (doc['end_time'] as Timestamp).toDate(),
        'resource_id': roomName,
      };
    }
    return reservations.values.toList();
  }

  Future<List<Map<String, dynamic>>> getWasherReservationsForDay(
      DateTime? selectedDate) async {
    if (selectedDate == null) return [];

    final selectedDateOnly =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

    final queryDate = FirebaseFirestore.instance
        .collection('reservations')
        .where('reservation_type', isEqualTo: 'washer')
        .where('date', isEqualTo: Timestamp.fromDate(selectedDateOnly));

    final queryEndTime = FirebaseFirestore.instance
        .collection('reservations')
        .where('reservation_type', isEqualTo: 'washer')
        .where(
          'end_time',
          isGreaterThanOrEqualTo: Timestamp.fromDate(selectedDateOnly),
        )
        .where(
          'end_time',
          isLessThan: Timestamp.fromDate(
            DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
              23,
              59,
              59,
            ),
          ),
        );

    final snapshotDate = await queryDate.get();
    final snapshotEndTime = await queryEndTime.get();

    final Map<String, Map<String, dynamic>> uniqueReservations = {};

    for (var doc in snapshotDate.docs) {
      uniqueReservations[doc.id] = {
        'start_time': (doc['start_time'] as Timestamp).toDate(),
        'end_time': (doc['end_time'] as Timestamp).toDate(),
        'resource_id': doc['resource_id'],
      };
    }

    for (var doc in snapshotEndTime.docs) {
      uniqueReservations[doc.id] ??= {
        'start_time': (doc['start_time'] as Timestamp).toDate(),
        'end_time': (doc['end_time'] as Timestamp).toDate(),
        'resource_id': doc['resource_id'],
      };
    }
    return uniqueReservations.values.toList();
  }

  Future<bool> isRoomAvailable(
    DateTime? selectedDate,
    DateTime? startDateTime,
    DateTime? endDateTime,
    String roomId,
  ) async {
    if (startDateTime == null || endDateTime == null) {
      return false;
    }
    final reservations = await getRoomReservationsForDay(selectedDate);
    for (var reservation in reservations) {
      final DateTime existingStart = reservation['start_time'];
      final DateTime existingEnd = reservation['end_time'];
      if (startDateTime.isBefore(existingEnd) &&
          endDateTime.isAfter(existingStart)) {
        if (reservation['resource_id'] == roomId &&
            !(endDateTime.isBefore(existingStart) ||
                startDateTime.isAfter(existingEnd))) {
          return false;
        }
      }
    }
    return true;
  }

  Future<List<String>> getAvailableWashers(
    DateTime? selectedDate,
    DateTime? startDateTime,
    DateTime? endDateTime,
  ) async {
    if (selectedDate == null || startDateTime == null || endDateTime == null) {
      throw ArgumentError(
          'selectedDate, startDateTime, and endDateTime cannot be null');
    }

    final allWashers = await fetchAllWashers();
    final reservations = await getWasherReservationsForDay(selectedDate);
    final Set<String> occupiedWashers = {};
    for (var reservation in reservations) {
      final DateTime startTime = reservation['start_time'];
      final DateTime endTime = reservation['end_time'];
      if (startDateTime.isBefore(endTime) && endDateTime.isAfter(startTime)) {
        final List<dynamic> resourceIds =
            reservation['resource_id'] as List<dynamic>;
        for (var resourceId in resourceIds) {
          if (resourceId is DocumentReference) {
            occupiedWashers.add(resourceId.id);
          }
        }
      }
    }

    return allWashers
        .where((washer) => !occupiedWashers.contains(washer))
        .toList();
  }

  Future<List<String>> fetchAllWashers() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('washers_for_reservation')
        .get();

    return snapshot.docs.map((doc) => doc.id).toList();
  }
}
