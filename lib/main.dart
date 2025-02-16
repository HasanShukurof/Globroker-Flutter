import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';
import 'package:globroker/screens/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
