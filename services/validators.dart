class Validators {
  static String? validatePhoneNumber(String value) {
    final phoneRegex = RegExp(r'^\d{9}$');
    if (value.isEmpty) {
      return "Numer telefonu jest wymagany.";
    }
    if (!phoneRegex.hasMatch(value)) {
      return "Numer telefonu musi zawierać dokładnie 9 cyfr.";
    }
    return null;
  }

  static String? validatePostalCode(String value) {
    final postalCodeRegex = RegExp(r'^\d{2}-\d{3}$');
    if (value.isEmpty) {
      return "Kod pocztowy jest wymagany.";
    }
    if (!postalCodeRegex.hasMatch(value)) {
      return "Kod pocztowy musi być w formacie XX-XXX.";
    }
    return null;
  }

  static String? validateCity(String value) {
    final cityRegex = RegExp(r'^[a-zA-Z\u00C0-\u017F\s]+$');
    if (value.isEmpty) {
      return "Miasto jest wymagane.";
    }
    if (!cityRegex.hasMatch(value)) {
      return "Miasto może zawierać tylko litery.";
    }
    return null;
  }

  static String? validateStreet(String value) {
    final streetRegex = RegExp(r'^[a-zA-Z\u00C0-\u017F\s]+$');
    if (value.isEmpty) {
      return "Ulica jest wymagana.";
    }
    if (!streetRegex.hasMatch(value)) {
      return "Nazwa ulicy może zawierać tylko litery.";
    }
    return null;
  }

  static String? validateBuildingNumber(String value) {
    final buildingNumberRegex = RegExp(r'^\d+$');
    if (value.isEmpty) {
      return "Numer budynku jest wymagany.";
    }
    if (!buildingNumberRegex.hasMatch(value)) {
      return "Numer budynku może zawierać tylko cyfry.";
    }
    return null;
  }

  static String? validateRoomNumber(String value) {
    final roomNumberRegex = RegExp(r'^\d+$');
    if (value.isEmpty) {
      return "Numer pokoju jest wymagany.";
    }
    if (!roomNumberRegex.hasMatch(value)) {
      return "Numer pokoju może zawierać tylko cyfry.";
    }
    return null;
  }
 static String? validateDaysSelected(List<bool> selectedDays) {
  if (selectedDays.isEmpty || !selectedDays.contains(true)) {
    return "Musisz wybrać przynajmniej jeden dzień pracy.";
  }
  return null;
}
}