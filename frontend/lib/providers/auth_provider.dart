import 'package:flutter/foundation.dart';
import 'package:flying_maths/auth_service.dart';

class FlyingMathAuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _userId;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get userId => _userId;
  // Initialize method that can be called at startup
  Future<void> initialize() async {
    await checkAuthStatus();
  }
  Future<void> checkAuthStatus() async {
    debugPrint('isAuthenticated start: $_isAuthenticated');
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      final result = await AuthService.isAuthenticated();
      _isAuthenticated = result;
      debugPrint('isAuthenticated result: $result');
    } catch (e) {
      _isAuthenticated = false;
      debugPrint('isAuthenticated: $_isAuthenticated');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      await AuthService.signOut();
      _isAuthenticated = false;
      _userId = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}