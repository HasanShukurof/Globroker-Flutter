import 'package:flutter/material.dart';
import 'package:globroker/screens/home_screen.dart';

void main() {
  runApp(const GloBroker());
}

class GloBroker extends StatefulWidget {
  const GloBroker({super.key});

  @override
  State<GloBroker> createState() => _GloBrokerState();
}

class _GloBrokerState extends State<GloBroker> {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}
