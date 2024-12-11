import 'package:firebase_test/main.dart';
import 'package:firebase_test/services/validators.dart';
import 'package:firebase_test/widgets/custom_time_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContactPage extends StatefulWidget {
  final String currentUserRole;
  const ContactPage({super.key, required this.currentUserRole});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _buildingNumberController =
      TextEditingController();
  final TextEditingController _roomNumberController = TextEditingController();

  String? _phoneError;
  String? _postalCodeError;
  String? _cityError;
  String? _streetError;
  String? _buildingNumberError;
  String? _roomNumberError;

  void _validateAllFields() {
    setState(() {
      _phoneError = Validators.validatePhoneNumber(_phoneController.text);
      _postalCodeError =
          Validators.validatePostalCode(_postalCodeController.text);
      _cityError = Validators.validateCity(_cityController.text);
      _streetError = Validators.validateStreet(_streetController.text);
      _buildingNumberError =
          Validators.validateBuildingNumber(_buildingNumberController.text);
      _roomNumberError =
          Validators.validateRoomNumber(_roomNumberController.text);

      final daysError = Validators.validateDaysSelected(_selectedDays);
      if (daysError != null && daysError.isNotEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(daysError)));
      }
    });
  }

  DateTime? _startTime;
  DateTime? _endTime;
  final List<String> _days = [
    "Poniedziałek",
    "Wtorek",
    "Środa",
    "Czwartek",
    "Piątek",
  ];
  final List<bool> _selectedDays = List.generate(5, (_) => false);

  bool _isEditMode = false;
  bool _isLoading = false;
  String? _managerId;
    String _name = "Nieznane imię i nazwisko";
  String _email = "Nieznany email";

  @override
  void initState() {
    super.initState();
    _fetchManagerId();
  }

  Future<void> _fetchManagerId() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final managerDoc = await FirebaseFirestore.instance
          .collection('user_statuses')
          .where('role', isEqualTo: 'manager')
          .limit(1)
          .get();

      if (managerDoc.docs.isNotEmpty) {
        final managerData = managerDoc.docs.first;
        _managerId = managerData.id;
        _fetchManagerDetails();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Błąd: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchManagerDetails() async {
    if (_managerId == null) return;

    try {
      final managerDoc = await FirebaseFirestore.instance
          .collection('user_statuses')
          .doc(_managerId)
          .get();

      if (managerDoc.exists) {
        final data = managerDoc.data()!;
        _phoneController.text = data['phone'] ?? '';
        _addressController.text = data['address'] ?? '';
        _postalCodeController.text = data['postalCode'] ?? '';
        _cityController.text = data['city'] ?? '';
        _streetController.text = data['street'] ?? '';
        _buildingNumberController.text = data['buildingNumber'] ?? '';
        _roomNumberController.text = data['roomNumber'] ?? '';

        _name = data['displayName'] ?? "Nieznane imię i nazwisko";
        _email = data['email'] ?? "Nieznany email";

        final hoursOfWork = data['hoursOfWork'] ?? {};
        if (hoursOfWork.isNotEmpty) {
          _startTime = _parseTime(hoursOfWork['start']);
          _endTime = _parseTime(hoursOfWork['end']);
          for (int i = 0; i < _days.length; i++) {
            _selectedDays[i] = hoursOfWork['days']?.contains(_days[i]) ?? false;
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Błąd podczas pobierania danych kierownika")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatAddress() {
    if (_postalCodeController.text.isEmpty ||
        _cityController.text.isEmpty ||
        _streetController.text.isEmpty ||
        _buildingNumberController.text.isEmpty ||
        _roomNumberController.text.isEmpty) {
      return "Adres nieznany";
    }

    return ("${_postalCodeController.text} ${_cityController.text}\n"
        "ul. ${_streetController.text} ${_buildingNumberController.text}\n"
        "sala: ${_roomNumberController.text}");
  }

  String _formatWorkingHours() {
    if (_selectedDays.every((selected) => !selected) ||
        _startTime == null ||
        _endTime == null) {
      return "Godziny pracy nieznane";
    }

    final Map<String, String> abbreviations = {
      "Poniedziałek": "pon",
      "Wtorek": "wt",
      "Środa": "śr",
      "Czwartek": "czw",
      "Piątek": "pt",
    };

    final selectedDays = _days
        .asMap()
        .entries
        .where((entry) => _selectedDays[entry.key])
        .map((entry) => entry.key)
        .toList();

    List<String> dayRanges = [];
    int start = 0;

    for (int i = 0; i < selectedDays.length; i++) {
      if (i == selectedDays.length - 1 ||
          selectedDays[i] + 1 != selectedDays[i + 1]) {
        if (start == i) {
          dayRanges.add(abbreviations[_days[selectedDays[start]]] ?? "");
        } else {
          dayRanges.add(
              "${abbreviations[_days[selectedDays[start]]]}-${abbreviations[_days[selectedDays[i]]]}");
        }
        start = i + 1;
      }
    }

    final dayRangesFormatted = dayRanges.join(" i ");
    return "$dayRangesFormatted\n${_formatTime(_startTime)} - ${_formatTime(_endTime)}";
  }

  DateTime? _parseTime(String? time) {
    if (time == null) return null;
    final parts = time.split(":");
    if (parts.length != 2) return null;
    return DateTime(0, 0, 0, int.parse(parts[0]), int.parse(parts[1]));
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  Future<void> _updateManagerDetails() async {
    if (_managerId == null) return;

    try {
      final hoursOfWork = {
        'start': _formatTime(_startTime),
        'end': _formatTime(_endTime),
        'days': _days
            .asMap()
            .entries
            .where((entry) => _selectedDays[entry.key])
            .map((entry) => entry.value)
            .toList(),
      };

      await FirebaseFirestore.instance
          .collection('user_statuses')
          .doc(_managerId)
          .set({
        'phone': _phoneController.text,
        'address': _formatAddress(),
        'postalCode': _postalCodeController.text,
        'city': _cityController.text,
        'street': _streetController.text,
        'buildingNumber': _buildingNumberController.text,
        'roomNumber': _roomNumberController.text,
        'hoursOfWork': hoursOfWork,
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Zaktualizowano dane kontaktowe.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Błąd podczas aktualizacji")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isManager = widget.currentUserRole == 'manager';
    return Scaffold(
      appBar: AppBar(
        title: Text(isManager
            ? "Moje dane kontaktowe"
            : "Kontakt do kierownika"),
        actions: (isManager && !_isLoading)
            ? _isEditMode
                ? [
                    IconButton(
                      icon: const Icon(Icons.save),
                      onPressed: () {
                        _validateAllFields();

                        if (_phoneError != null ||
                            _postalCodeError != null ||
                            _cityError != null ||
                            _streetError != null ||
                            _buildingNumberError != null ||
                            _roomNumberError != null ||
                            _startTime == null ||
                            _endTime == null ||
                            !_selectedDays.contains(true)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text("Uzupełnij wszystkie wymagane pola."),
                            ),
                          );
                          return;
                        }
                        _updateManagerDetails();
                        setState(() {
                          _isEditMode = false;
                        });
                      },
                    ),
                  ]
                : [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        setState(() {
                          _isEditMode = true;
                        });
                      },
                    ),
                  ]
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  if (!_isEditMode) ...[
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(
                       _name,
                      ),
                      subtitle: Text(
                        "Imię i nazwisko",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.email),
                      title: Text( _email),
                      subtitle: Text("Email",
                          style: Theme.of(context).textTheme.bodySmall),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.phone),
                      title: Text("+48 ${_phoneController.text}"),
                      subtitle: Text("Numer telefonu",
                          style: Theme.of(context).textTheme.bodySmall),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.location_on),
                      title: Text(_formatAddress()),
                      subtitle: Text("Adres",
                          style: Theme.of(context).textTheme.bodySmall),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: Text(_formatWorkingHours()),
                      subtitle: Text("Godziny pracy",
                          style: Theme.of(context).textTheme.bodySmall),
                    ),
                  ],
                  if (_isEditMode) ...[
                    Container(
                      decoration: context.containerDecoration,
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: "Numer telefonu",
                          prefixText: "+48 ",
                          prefixIcon: const Icon(Icons.phone),
                          errorText: _phoneError,
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.transparent),
                          ),
                        ),
                        onChanged: (_) => _validateAllFields(),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Container(
                      decoration: context.containerDecoration,
                      child: TextField(
                        controller: _postalCodeController,
                        decoration: InputDecoration(
                          labelText: "Kod pocztowy",
                          prefixIcon: const Icon(Icons.local_post_office),
                          errorText: _postalCodeError,
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.transparent),
                          ),
                        ),
                        onChanged: (_) => _validateAllFields(),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Container(
                      decoration: context.containerDecoration,
                      child: TextField(
                        controller: _cityController,
                        decoration: InputDecoration(
                          labelText: "Miasto",
                          prefixIcon: const Icon(Icons.location_city),
                          errorText: _cityError,
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.transparent),
                          ),
                        ),
                        onChanged: (_) => _validateAllFields(),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Container(
                      decoration: context.containerDecoration,
                      child: TextField(
                        controller: _streetController,
                        decoration: InputDecoration(
                          labelText: "Ulica",
                          prefixIcon: const Icon(Icons.map),
                          errorText: _streetError,
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.transparent),
                          ),
                        ),
                        onChanged: (_) => _validateAllFields(),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Container(
                      decoration: context.containerDecoration,
                      child: TextField(
                        controller: _buildingNumberController,
                        decoration: InputDecoration(
                          labelText: "Numer budynku",
                          prefixIcon: const Icon(Icons.home),
                          errorText: _buildingNumberError,
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.transparent),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _validateAllFields(),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Container(
                      decoration: context.containerDecoration,
                      child: TextField(
                        controller: _roomNumberController,
                        decoration: InputDecoration(
                          labelText: "Numer pokoju",
                          prefixIcon: const Icon(Icons.meeting_room),
                          errorText: _roomNumberError,
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.transparent),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _validateAllFields(),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text("Dni pracy",
                        style: Theme.of(context).textTheme.bodyLarge),
                    Wrap(
                      spacing: 8.0,
                      children: List.generate(
                        _days.length,
                        (index) => FilterChip(
                          label: Text(_days[index]),
                          selected: _selectedDays[index],
                          onSelected: (selected) {
                            setState(() {
                              _selectedDays[index] = selected;
                            });
                          },
                        ),
                      ),
                    ),
                    if (Validators.validateDaysSelected(_selectedDays)
                            ?.isNotEmpty ??
                        false)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          Validators.validateDaysSelected(_selectedDays) ?? "",
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                    const SizedBox(
                      height: 10,
                    ),
                    Container(
                      decoration: context.containerDecoration,
                      child: TimePickerWidget(
                        labelText: "Godzina rozpoczęcia pracy",
                        selectedTime: _startTime,
                        onTimeSelected: (time) => setState(() {
                          _startTime = time;
                        }),
                        isStartTime: true,
                        selectedDate: DateTime.now(),
                        ignoreStartTimeCheck: true,
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Container(
                      decoration: context.containerDecoration,
                      child: TimePickerWidget(
                        labelText: "Godzina zakończenia pracy",
                        selectedTime: _endTime,
                        onTimeSelected: (time) => setState(() {
                          _endTime = time;
                        }),
                        isStartTime: false,
                        selectedDate: DateTime.now(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
