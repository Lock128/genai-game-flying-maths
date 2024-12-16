import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_api/amplify_api.dart';

import 'amplifyconfiguration.dart';
import 'widgets/my_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _configureAmplify();
  runApp(const MyApp());
}

Future<void> _configureAmplify() async {
  try {
    final api = AmplifyAPI();
    final auth = AmplifyAuthCognito();
    await Amplify.addPlugins([api, auth]);
    await Amplify.configure(amplifyconfig);
  } catch (e) {
    print('An error occurred while configuring Amplify: $e');
  }
}