import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flag/flag.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../amplifyconfiguration.dart';
import 'my_home_page.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _currentLocale = const Locale('de');
  void setLocale(Locale locale) {
    setState(() {
      _currentLocale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
      return MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('de'),
            Locale('en'),
            Locale('tr'),
            Locale('pl'),
            Locale('es'),
            Locale('ar'),
          ],
          locale: _currentLocale,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              elevation: 4,
            ),
          ),
          home: MyHomePage(
            onLanguageChanged: setLocale,
          ),
        ),
        
      );
  }
}