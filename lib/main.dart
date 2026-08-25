import 'package:flutter/material.dart';
import 'screens/invite_screen.dart';

void main() {
  runApp(const TeryaqApp());
}

class TeryaqApp extends StatelessWidget {
  const TeryaqApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ترياق - منبه الأدوية الذكي',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: const InviteScreen(),
    );
  }
}
