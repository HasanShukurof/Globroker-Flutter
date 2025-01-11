import 'package:flutter_localizations/flutter_localizations.dart';
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
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('az', 'AZ'), // Azerice
      ],
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}
