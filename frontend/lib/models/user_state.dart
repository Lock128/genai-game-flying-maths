import 'package:flutter/foundation.dart';

class UserState extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _userId;

  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _userId;

  void setAuthenticated(bool value, {String? userId}) {
    _isAuthenticated = value;
    _userId = userId;
    notifyListeners();
  }

  void clearAuth() {
    _isAuthenticated = false;
    _userId = null;
    notifyListeners();
  }
}