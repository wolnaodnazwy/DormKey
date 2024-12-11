import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyReservationsPage extends StatefulWidget {
  const MyReservationsPage({super.key});

  @override
  _MyReservationsPageState createState() => _MyReservationsPageState();
}

class _MyReservationsPageState extends State<MyReservationsPage> {
  String _searchQuery = "";
  String? _selectedFilter;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  final List<String> _filterOptions = [
    "Zakończone",
    "Trwające",
    "Nadchodzące",
  ];

  Stream<List<Map<String, dynamic>>> _fetchUserReservationsStream() {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection('reservations')
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
      return Future.wait(snapshot.docs.map((doc) async {
        final data = doc.data();
        final reservationType = data['reservation_type'] ?? "unknown";
        final resourceId = data['resource_id'];

        final resourceNames =
            await _fetchResourceNames(resourceId, reservationType);

        return {
          'documentId': doc.id,
          'reservationType': reservationType,
          'resourceNames': resourceNames.join(", "),
          'startTime': (data['start_time'] as Timestamp?)?.toDate(),
          'endTime': (data['end_time'] as Timestamp?)?.toDate(),
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

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Moje rezerwacje"),
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
                  hintText: "Wpisz typ, datę lub zasób",
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
                stream: _fetchUserReservationsStream(),
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
                        formattedEndTime.contains(_searchQuery);
                  }).toList();

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
                                  const SizedBox(height: 8),
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
                            Row(
                              children: [
                                const SizedBox(width: 16),
                                if (DateTime.now().isBefore(
                                    reservation['startTime'] as DateTime))
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
