import 'package:flutter/material.dart';

class ToggleReservationType extends StatelessWidget {
  final String reservationType;
  final ValueChanged<String> onTypeChanged;

  const ToggleReservationType({
    super.key,
    required this.reservationType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ToggleButtons(
      isSelected: [
        reservationType == 'room',
        reservationType == 'washer',
      ],
      onPressed: (index) {
        onTypeChanged(index == 0 ? 'room' : 'washer');
      },
      children: const [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
          child: Text("Pokój"),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
          child: Text("Pralka"),
        ),
      ],
    );
  }
}
