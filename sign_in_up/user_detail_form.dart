import 'package:firebase_test/navigation/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserDetailsForm extends StatefulWidget {
  final String uid;
  const UserDetailsForm({Key? key, required this.uid}) : super(key: key);

  @override
  _UserDetailsFormState createState() => _UserDetailsFormState();
}

class _UserDetailsFormState extends State<UserDetailsForm> {
  final _formKey = GlobalKey<FormState>();
  String? _dormitoryNumber;
  String? _roomNumber;
  String? _province;

  final List<String> _provinces = [
    'Dolnośląskie',
    'Kujawsko-Pomorskie',
    'Lubelskie',
    'Lubuskie',
    'Łódzkie',
    'Małopolskie',
    'Mazowieckie',
    'Opolskie',
    'Podkarpackie',
    'Podlaskie',
    'Pomorskie',
    'Śląskie',
    'Świętokrzyskie',
    'Warmińsko-Mazurskie',
    'Wielkopolskie',
    'Zachodniopomorskie',
    'Inne'
  ];

  Future<void> _saveDetails() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      await FirebaseFirestore.instance
          .collection('user_statuses')
          .doc(widget.uid)
          .update({
        'dormitory_number': _dormitoryNumber,
        'room_number': _roomNumber,
        'province': _province,
      });
      setState(() {});

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Uzupełnij dane"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Numer akademika'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Pole wymagane';
                  } else if (!RegExp(r'^\d+$').hasMatch(value)) {
                    return 'Wpisz tylko cyfry!';
                  }
                  return null;
                },
                onSaved: (value) => _dormitoryNumber = 'T-$value',
              ),
              SizedBox(
                height: 16,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Numer pokoju'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Pole wymagane';
                  } else if (!RegExp(r'^\d+$').hasMatch(value)) {
                    return 'Wpisz tylko cyfry!';
                  }
                  return null;
                },
                onSaved: (value) => _roomNumber = value,
              ),
              SizedBox(
                height: 16,
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Województwo z którego pochodzisz',
                ),
                items: _provinces.map((province) {
                  return DropdownMenuItem(
                    value: province,
                    child: Text(province),
                  );
                }).toList(),
                onChanged: (value) => _province = value,
                dropdownColor: Theme.of(context).colorScheme.onPrimary,
                validator: (value) =>
                    value == null ? 'Proszę wybrać województwo' : null,
              ),
              const SizedBox(height: 20),
              Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.5,
                  child: ElevatedButton(
                    onPressed: _saveDetails,
                    child: const Text("Zapisz"),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
