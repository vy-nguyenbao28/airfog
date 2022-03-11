import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mist_app/drawer/personal_page.dart';
import 'package:mist_app/home.dart';
import 'package:mist_app/login/loading.dart';
import 'package:mist_app/switch/switch_check.dart';
import 'package:mist_app/switch/switch_history.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('vi')
      ],
      debugShowCheckedModeBanner: false,
      title: 'Mist App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Loading(),
      routes: <String, WidgetBuilder>{
        '/home': (BuildContext context) => Home(),
      },
    );
  }
}