import 'package:flutter/material.dart';

class TimePickerWidget extends StatelessWidget {
  final String labelText;
  final DateTime? selectedDate;
  final DateTime? selectedTime;
  final DateTime? startTime;
  final Function(DateTime) onTimeSelected;
  final bool isStartTime;
  final bool ignoreStartTimeCheck;

  const TimePickerWidget({
    super.key,
    required this.labelText,
    required this.selectedDate,
    required this.selectedTime,
    this.startTime,
    required this.onTimeSelected,
    required this.isStartTime,
    this.ignoreStartTimeCheck = false,
  });

  Future<void> _showTimePicker(BuildContext context) async {
    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Najpierw wybierz datę."),
        ),
      );
      return;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selectedTime ?? DateTime.now()),
      initialEntryMode: TimePickerEntryMode.input,
      builder: (BuildContext context, Widget? child) {
        return Localizations.override(
          context: context,
          locale: const Locale('pl'),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: child!,
          ),
        );
      },
    );

    if (pickedTime != null) {
      final now = DateTime.now();
      final pickedDateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        pickedTime.hour,
        pickedTime.minute,
      );

        if (!ignoreStartTimeCheck && isStartTime) {
          if (pickedDateTime.isBefore(now)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Czas początkowy nie może być w przeszłości."),
              ),
            );
            return;
          }
          onTimeSelected(pickedDateTime);
        } else {
          DateTime adjustedDateTime = pickedDateTime;
          if (startTime != null && pickedDateTime.isBefore(startTime!)) {
            adjustedDateTime = pickedDateTime.add(const Duration(days: 1));
          }

          onTimeSelected(adjustedDateTime);
        }
      
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showTimePicker(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: labelText,
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.transparent),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.transparent),
          ),
        ),
        child: Text(
          selectedTime != null
              ? "${selectedTime!.hour}:${selectedTime!.minute.toString().padLeft(2, '0')}"
              : "Wybierz godzinę",
        ),
      ),
    );
  }
}
