import 'package:flutter/material.dart';
import 'package:xl_flutter/home/home_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: '',
      home: HomePage(),
    );
  }
}
