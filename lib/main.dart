import 'package:flutter/material.dart';
import 'package:pass_generator/pages/auth_check_page.dart' show AuthCheckScreen;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Password Generator',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const AuthCheckScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
