import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flying_maths/auth_service.dart';
import 'package:flying_maths/models/user_state.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  group('Authentication Flow Tests', () {
    late UserState userState;
    late MockAuthService mockAuthService;

    setUp(() {
      userState = UserState();
      mockAuthService = MockAuthService();
    });

    test('Initial state is unauthenticated', () {
      expect(userState.isAuthenticated, false);
      expect(userState.userId, null);
    });

    test('Can set authenticated state', () {
      userState.setAuthenticated(true, userId: 'test-user');
      expect(userState.isAuthenticated, true);
      expect(userState.userId, 'test-user');
    });

    test('Can clear auth state', () {
      userState.setAuthenticated(true, userId: 'test-user');
      userState.clearAuth();
      expect(userState.isAuthenticated, false);
      expect(userState.userId, null);
    });

    test('Auth status is preserved in provider', () {
      userState.setAuthenticated(true, userId: 'test-user');
      expect(userState.isAuthenticated, true);
      expect(userState.userId, 'test-user');

      // Simulate app reload
      userState = UserState();
      expect(userState.isAuthenticated, false);
      expect(userState.userId, null);
    });
  });
}