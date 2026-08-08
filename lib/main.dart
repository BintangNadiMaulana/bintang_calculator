import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:calculator_bintang/screens/simple_calculator.dart';

/// Warna latar aplikasi, dipakai juga untuk navigation bar sistem
/// agar tampilannya menyatu dengan layar.
const _backgroundColor = Color(0xFF101014);

void main() {
  // Wajib dipanggil sebelum memakai API platform seperti `SystemChrome`.
  WidgetsFlutterBinding.ensureInitialized();

  // Kalkulator dirancang untuk mode potret; rotasi akan merusak
  // proporsi tombol.
  SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: _backgroundColor,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator Bintang',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _backgroundColor,
        useMaterial3: false,
      ),
      home: const SimpleCalculator(),
    );
  }
}
