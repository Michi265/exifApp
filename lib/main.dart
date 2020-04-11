import 'package:flutter/material.dart';
import 'package:exifapp/Pages/home.dart';
import 'dart:math';

void main() => runApp(MyApp());


class MyApp extends StatelessWidget {
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Exif Image Viewer',
      theme: ThemeData(
        primaryColor: Colors.white,
      ),
      home: Home(),
    );

  }
}
