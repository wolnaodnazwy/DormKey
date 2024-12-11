import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AllReservationsPage extends StatefulWidget {
  const AllReservationsPage({super.key});

  @override
  _AllReservationsPageState createState() => _AllReservationsPageState();
}

class _AllReservationsPageState extends State<AllReservationsPage> {
  String _searchQuery = "";
  String? _selectedFilter;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  final List<String> _filterOptions = [
    "Zakończone",
    "Trwające",
    "Nadchodzące",
  ];

  Stream<List<Map<String, dynamic>>> _fetchAllReservationsStream() {
    return FirebaseFirestore.instance
        .collection('reservations')
        .snapshots()
        .asyncMap((snapshot) async {
      return Future.wait(snapshot.docs.map((doc) async {
        final data = doc.data();
        final reservationType = data['reservation_type'] ?? "unknown";
        final resourceId = data['resource_id'];
        final userId = data['user_id'];

        final resourceNames =
            await _fetchResourceNames(resourceId, reservationType);
        final userName = await _fetchUserName(userId);

        return {
          'documentId': doc.id,
          'reservationType': reservationType,
          'resourceNames': resourceNames.join(", "),
          'startTime': (data['start_time'] as Timestamp?)?.toDate(),
          'endTime': (data['end_time'] as Timestamp?)?.toDate(),
          'userName': userName,
        };
      }).toList());
    });
  }

  Future<List<String>> _fetchResourceNames(
      dynamic resourceId, String type) async {
    if (type == 'room' && resourceId is DocumentReference) {
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
  }

  Future<String> _fetchUserName(String userId) async {
    if (userId.isEmpty) return "Nieznany użytkownik";

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('user_statuses')
          .doc(userId)
          .get();

      final data = userDoc.data();
      return data?['displayName'] ?? "Nieznany użytkownik";
    } catch (e) {
      print("Error fetching user name: $e");
      return "Nieznany użytkownik";
    }
  }

  Future<void> _deleteReservation(String documentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('reservations')
          .doc(documentId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Rezerwacja została usunięta.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Nie udało się usunąć rezerwacji: $e")),
      );
    }
  }

  void _showDeleteConfirmationDialog(String documentId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Potwierdzenie",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          content: Text(
            "Czy na pewno chcesz usunąć tę rezerwację? \n\n"
            "Ta operacja jest nieodwracalna i nie będzie można jej cofnąć.",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Anuluj"),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
              ),
              onPressed: () async {
                await _deleteReservation(documentId);
                Navigator.of(context).pop();
              },
              child: const Text("Usuń"),
            ),
          ],
        );
      },
    );
  }

  void _showEditReservationDialog(
      String documentId, DateTime currentStartTime, DateTime currentEndTime) {
    final startTimeController = TextEditingController(
      text:
          "${currentStartTime.hour.toString().padLeft(2, '0')}:${currentStartTime.minute.toString().padLeft(2, '0')}",
    );
    final endTimeController = TextEditingController(
      text:
          "${currentEndTime.hour.toString().padLeft(2, '0')}:${currentEndTime.minute.toString().padLeft(2, '0')}",
    );

    DateTime newStartTime = currentStartTime;
    DateTime newEndTime = currentEndTime;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Edytuj rezerwację",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: startTimeController,
                decoration: const InputDecoration(
                  labelText: "Godzina rozpoczęcia (HH:mm)",
                ),
                keyboardType: TextInputType.datetime,
                onChanged: (value) {
                  final timeParts = value.split(":");
                  if (timeParts.length == 2) {
                    final hours =
                        int.tryParse(timeParts[0]) ?? currentStartTime.hour;
                    final minutes =
                        int.tryParse(timeParts[1]) ?? currentStartTime.minute;
                    newStartTime = DateTime(
                      currentStartTime.year,
                      currentStartTime.month,
                      currentStartTime.day,
                      hours,
                      minutes,
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: endTimeController,
                decoration: const InputDecoration(
                  labelText: "Godzina zakończenia (HH:mm)",
                ),
                keyboardType: TextInputType.datetime,
                onChanged: (value) {
                  final timeParts = value.split(":");
                  if (timeParts.length == 2) {
                    final hours =
                        int.tryParse(timeParts[0]) ?? currentEndTime.hour;
                    final minutes =
                        int.tryParse(timeParts[1]) ?? currentEndTime.minute;
                    newEndTime = DateTime(
                      currentEndTime.year,
                      currentEndTime.month,
                      currentEndTime.day,
                      hours,
                      minutes,
                    );
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Anuluj"),
            ),
            TextButton(
              onPressed: () async {
                if (newStartTime.isAfter(newEndTime)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            "Godzina rozpoczęcia musi być wcześniejsza od godziny zakończenia.")),
                  );
                  return;
                }

                try {
                  await FirebaseFirestore.instance
                      .collection('reservations')
                      .doc(documentId)
                      .update({
                    'start_time': newStartTime,
                    'end_time': newEndTime,
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Rezerwacja została zaktualizowana.")),
                  );
                  Navigator.of(context).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Błąd podczas aktualizacji: $e")),
                  );
                }
              },
              child: const Text("Zapisz"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Zarządzaj rezerwacjami"),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: const InputDecoration(
                  labelText: "Wyszukaj rezerwację",
                  hintText: "Wpisz typ, datę, zasób lub użytkownika",
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
            Wrap(
              spacing: 8.0,
              children: _filterOptions.map((filter) {
                final isSelected = _selectedFilter == filter;

                return ChoiceChip(
                  label: Text(
                    filter,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _selectedFilter == filter
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedFilter = isSelected ? null : filter;
                    });
                  },
                  selectedColor: Theme.of(context).colorScheme.primary,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _fetchAllReservationsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        "Brak rezerwacji",
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    );
                  }

                  final reservations = snapshot.data!.where((reservation) {
                    final startTime = reservation['startTime'] as DateTime?;
                    final endTime = reservation['endTime'] as DateTime?;
                    if (startTime == null || endTime == null) {
                      return false;
                    }

                    if (_selectedFilter == _filterOptions[1]) {
                      return now.isAfter(startTime) && now.isBefore(endTime);
                    } else if (_selectedFilter == _filterOptions[0]) {
                      return now.isAfter(endTime);
                    } else if (_selectedFilter == _filterOptions[2]) {
                      return now.isBefore(startTime);
                    }
                    return true;
                  }).where((reservation) {
                    final resourceNames =
                        reservation['resourceNames'] as String;
                    final userName = reservation['userName'] as String?;
                    final startTime = reservation['startTime'] as DateTime?;
                    final endTime = reservation['endTime'] as DateTime?;

                    final formattedStartTime = startTime != null
                        ? "${startTime.day.toString().padLeft(2, '0')}.${startTime.month.toString().padLeft(2, '0')}.${startTime.year}"
                        : "";
                    final formattedEndTime = endTime != null
                        ? "${endTime.day.toString().padLeft(2, '0')}.${endTime.month.toString().padLeft(2, '0')}.${endTime.year}"
                        : "";

                    return resourceNames.toLowerCase().contains(_searchQuery) ||
                        formattedStartTime.contains(_searchQuery) ||
                        formattedEndTime.contains(_searchQuery) ||
                        userName!.toLowerCase().contains(_searchQuery);
                  }).toList();

                  reservations.sort((a, b) {
                    final aStartTime = a['startTime'] as DateTime?;
                    final bStartTime = b['startTime'] as DateTime?;

                    return (bStartTime ?? DateTime(0))
                        .compareTo(aStartTime ?? DateTime(0));
                  });

                  if (reservations.isEmpty) {
                    return Center(
                      child: Text(
                        "Nie znaleziono wyników",
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: reservations.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final reservation = reservations[index];
                      final resourceNames = reservation['resourceNames'];
                      final userName =
                          reservation['userName'] ?? 'Nieznany użytkownik';
                      final startTime = reservation['startTime'] as DateTime?;
                      final endTime = reservation['endTime'] as DateTime?;
                      final formattedStartTime = startTime != null
                          ? "${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}, ${startTime.day.toString().padLeft(2, '0')}.${startTime.month.toString().padLeft(2, '0')}.${startTime.year}"
                          : "Brak danych";
                      final formattedEndTime = endTime != null
                          ? "${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}, ${endTime.day.toString().padLeft(2, '0')}.${endTime.month.toString().padLeft(2, '0')}.${endTime.year}"
                          : "Brak danych";

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 12.0,
                        ),
                        margin: const EdgeInsets.symmetric(
                          vertical: 4.0,
                          horizontal: 12.0,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              DateTime.now().isAfter(
                                      reservation['endTime'] as DateTime)
                                  ? Icons.event_busy
                                  : (reservation['reservationType'] == 'room'
                                      ? Icons.meeting_room
                                      : Icons.local_laundry_service),
                              color: DateTime.now().isAfter(
                                      reservation['endTime'] as DateTime)
                                  ? Theme.of(context).colorScheme.outline
                                  : Theme.of(context).colorScheme.secondary,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    resourceNames,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Użytkownik: $userName",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Od: $formattedStartTime",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                                  Text(
                                    "Do: $formattedEndTime",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            if (DateTime.now()
                                .isBefore(reservation['startTime'] as DateTime))
                              Row(
                                children: [
                                  const SizedBox(width: 16),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color:
                                          Theme.of(context).colorScheme.error,
                                    ),
                                    onPressed: () =>
                                        _showDeleteConfirmationDialog(
                                      reservation['documentId'],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.edit,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    onPressed: () => _showEditReservationDialog(
                                      reservation['documentId'],
                                      reservation['startTime'] as DateTime,
                                      reservation['endTime'] as DateTime,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
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
}
