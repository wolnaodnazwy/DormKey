import 'package:flutter/material.dart';

class UserRoleProvider extends ChangeNotifier {
  String? _role;

  String? get role => _role;

  void setRole(String role) {
    _role = role;
    notifyListeners();
  }
}