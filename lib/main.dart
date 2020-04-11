import 'package:flutter/material.dart';
import 'package:exifapp/Pages/home.dart';
import 'dart:math';

void main() => runApp(MyApp());


class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgeMob User',
      theme: ThemeData(
        primaryColor: Colors.white,
      ),
      home: Home(),
    );

  }
}