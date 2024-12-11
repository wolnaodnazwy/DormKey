import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import '../widgets/custom_date_picker.dart';
import '../widgets/reservation_list_widget.dart';
import '../widgets/toggle_buttons.dart';
import '../services/reservation_service.dart';
import '../widgets/custom_time_picker.dart';
import '../main.dart';

class ReservationPage extends StatefulWidget {
  const ReservationPage({super.key});

  @override
  State<ReservationPage> createState() => _ReservationPageState();
}

class _ReservationPageState extends State<ReservationPage> {
  String reservationType = 'room';
  String? selectedRoom;
  int reservedWashers = 0;
  final int maxWashers = 3;
  DateTime? selectedDate;
  DateTime? startDateTime;
  DateTime? endDateTime;

  final ReservationService _reservationService = ReservationService();
  final TextEditingController washersController = TextEditingController();

  Future<void> _showReservationsForDay() async {
    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Proszę wybrać datę przed sprawdzeniem rezerwacji.")),
      );
      return;
    }

    final reservations = reservationType == 'room'
        ? await _reservationService.getRoomReservationsForDay(selectedDate)
        : await _reservationService.getWasherReservationsForDay(selectedDate);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (context) {
        final initialChildSize = (reservations.length * 0.1).clamp(0.2, 0.5);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Navigator.of(context).pop();
          },
          child: DraggableScrollableSheet(
            initialChildSize: initialChildSize,
            minChildSize: 0.2,
            maxChildSize: 0.75,
            builder: (context, scrollController) {
              return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: ReservationListWidget(
                      reservations: reservations,
                      reservationType: reservationType));
            },
          ),
        );
      },
    );
  }

  Future<void> _submitWasherReservation() async {
    final availableWashers = await _reservationService.getAvailableWashers(
        selectedDate, startDateTime, endDateTime);

    if (availableWashers.length < reservedWashers) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "W podanym przedziale czasowym dostępna liczba pralek to: ${availableWashers.length}",
          ),
        ),
      );
      return;
    }

    final random = Random();
    final List<String> selectedWasherIds = List.generate(
      reservedWashers,
      (_) => availableWashers.removeAt(random.nextInt(availableWashers.length)),
    );

    final List<DocumentReference> washerReferences = selectedWasherIds
        .map(
          (id) => FirebaseFirestore.instance
              .collection('washers_for_reservation')
              .doc(id),
        )
        .toList();

    final reservationData = {
      "reservation_type": "washer",
      "resource_id": washerReferences,
      "date": Timestamp.fromDate(selectedDate!),
      "start_time": Timestamp.fromDate(startDateTime!),
      "end_time": Timestamp.fromDate(endDateTime!),
      "user_id": FirebaseAuth.instance.currentUser?.uid,
    };

    await FirebaseFirestore.instance
        .collection('reservations')
        .add(reservationData);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Rezerwacja została złożona")),
    );

    setState(() {
      reservedWashers = 0;
      selectedDate = null;
      startDateTime = null;
      endDateTime = null;
    });
    washersController.text = '';
  }

  Future<void> _submitRoomReservation() async {
    if (selectedRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Proszę wybrać pokój.")),
      );
      return;
    }

    final roomReference = FirebaseFirestore.instance
        .collection('rooms_for_reservation')
        .doc(selectedRoom);

    final isAvailable = await _reservationService.isRoomAvailable(
        selectedDate, startDateTime, endDateTime, selectedRoom!);

    if (!isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Pokój $selectedRoom jest zajęty w wybranym przedziale czasowym.",
          ),
        ),
      );
      return;
    }

    final reservationData = {
      "reservation_type": "room",
      "resource_id": roomReference,
      "date": Timestamp.fromDate(selectedDate!),
      "start_time": Timestamp.fromDate(startDateTime!),
      "end_time": Timestamp.fromDate(endDateTime!),
      "user_id": FirebaseAuth.instance.currentUser?.uid,
    };

    await FirebaseFirestore.instance
        .collection('reservations')
        .add(reservationData);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Rezerwacja została złożona")),
    );

    setState(() {
      selectedRoom = null;
      selectedDate = null;
      startDateTime = null;
      endDateTime = null;
    });
  }

  Future<List<Map<String, String>>> _fetchRooms() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('rooms_for_reservation')
        .get();

    return snapshot.docs.map((doc) {
      return {'id': doc.id, 'name': doc['name'] as String};
    }).toList();
  }

  void _submitReservation() {
    if (selectedDate == null || startDateTime == null || endDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Proszę uzupełnić datę i godziny.")),
      );
      return;
    }

    if (reservationType == 'room') {
      _submitRoomReservation();
    } else if (reservationType == 'washer') {
      if (reservedWashers <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Proszę wprowadzić liczbę pralek do rezerwacji.")),
        );
        return;
      }
      _submitWasherReservation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    "Co chciałbyś zarezerwować?",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: ToggleReservationType(
                    reservationType: reservationType,
                    onTypeChanged: (type) {
                      setState(() {
                        reservationType = type;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 24),
                if (reservationType == 'washer') ...[
                  Container(
                    decoration: context.containerDecoration,
                    child: TextFormField(
                      controller: washersController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Liczba pralek",
                        hintText: "Wprowadź liczbę (max $maxWashers)",
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 15.0, horizontal: 12),
                        hintStyle: Theme.of(context).textTheme.bodyMedium,
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              const BorderSide(color: Colors.transparent),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              const BorderSide(color: Colors.transparent),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) {
                        final int? enteredValue = int.tryParse(value);
                        if (enteredValue != null &&
                            enteredValue <= maxWashers) {
                          setState(() {
                            reservedWashers = enteredValue;
                          });
                        } else {
                          setState(() {
                            reservedWashers = 0;
                          });
                        }
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Container(
                  decoration: context.containerDecoration,
                  child: CustomDatePicker(
                    selectedDate: selectedDate,
                    onDateSelected: (date) {
                      setState(() {
                        selectedDate = date;
                        if (startDateTime != null) {
                          startDateTime = DateTime(
                            selectedDate!.year,
                            selectedDate!.month,
                            selectedDate!.day,
                            startDateTime!.hour,
                            startDateTime!.minute,
                          );
                        }

                        if (endDateTime != null) {
                          endDateTime = DateTime(
                            selectedDate!.year,
                            selectedDate!.month,
                            selectedDate!.day,
                            endDateTime!.hour,
                            endDateTime!.minute,
                          );
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  children: [
                    Center(
                      child: selectedDate != null
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton(
                                  onPressed: _showReservationsForDay,
                                  child: const Text(
                                      "Sprawdź rezerwacje dla tego dnia"),
                                ),
                                const SizedBox(height: 16)
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: context.containerDecoration,
                        child: TimePickerWidget(
                          labelText: "Godzina początkowa",
                          selectedDate: selectedDate,
                          selectedTime: startDateTime,
                          onTimeSelected: (newTime) {
                            setState(() {
                              startDateTime = DateTime(
                                selectedDate!.year,
                                selectedDate!.month,
                                selectedDate!.day,
                                newTime.hour,
                                newTime.minute,
                              );
                            });
                          },
                          isStartTime: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        decoration: context.containerDecoration,
                        child: TimePickerWidget(
                          labelText: "Godzina końcowa",
                          selectedDate: selectedDate,
                          selectedTime: endDateTime,
                          startTime: startDateTime,
                          onTimeSelected: (newTime) {
                            setState(() {
                              endDateTime = newTime;
                            });
                          },
                          isStartTime: false,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  alignment: Alignment.center,
                  child: const FractionallySizedBox(
                    widthFactor: 0.9,
                    child: Divider(),
                  ),
                ),
                const SizedBox(height: 16),
                if (reservationType == 'room') ...[
                  if (selectedDate == null ||
                      startDateTime == null ||
                      endDateTime == null)
                    ...[]
                  else ...[
                    FutureBuilder<List<Map<String, String>>>(
                      future: _fetchRooms(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Text("Brak dostępnych pokoi");
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: snapshot.data!.map((room) {
                            final roomId = room['id']!;
                            final roomName = room['name']!;

                            return FutureBuilder<bool>(
                              future: _reservationService.isRoomAvailable(
                                  selectedDate,
                                  startDateTime,
                                  endDateTime,
                                  roomId),
                              builder: (context, availabilitySnapshot) {
                                if (availabilitySnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const LinearProgressIndicator();
                                }
                                final isAvailable =
                                    availabilitySnapshot.data ?? false;
                                if (!isAvailable) {
                                  return const SizedBox.shrink();
                                }

                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Container(
                                    decoration:
                                        context.containerDecoration.copyWith(
                                      color: selectedRoom == roomId
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primaryContainer
                                          : Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16.0),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      title: Text(
                                        roomName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: selectedRoom == roomId
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .onPrimaryContainer
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                              fontWeight: selectedRoom == roomId
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                      ),
                                      leading: Icon(
                                        Icons.meeting_room,
                                        color: selectedRoom == roomId
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onPrimary
                                            : Theme.of(context)
                                                .colorScheme
                                                .primary,
                                      ),
                                      onTap: () {
                                        setState(() {
                                          selectedRoom = roomId;
                                        });
                                      },
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ],
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    onPressed: _submitReservation,
                    child: const Text("Zarezerwuj"),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
