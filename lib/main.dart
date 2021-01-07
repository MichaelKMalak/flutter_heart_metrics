import 'package:flutter/material.dart';

import 'modules/home_page/home_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Heart Metrics',
      theme: ThemeData.light().copyWith(primaryColor: Colors.indigo),
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}
