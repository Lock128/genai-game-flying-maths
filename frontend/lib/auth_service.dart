import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static Future<AuthSession> getCurrentSession() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      return session;
    } catch (e) {
      print('Error fetching auth session: $e');
      rethrow;
    }
  }

  static Future<void> signOut() async {
    try {
      await Amplify.Auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  static Future<bool> isAuthenticated() async {
    try {
      final session = await getCurrentSession();
      return session.isSignedIn;
    } catch (e) {
      return false;
    }
  }
}