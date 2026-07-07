import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'api_config.dart';

const Color utamaHijau = Color(0xFF1B5E20);
const Color latarAbu = Color(0xFFF4F7F4);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.loadSavedIp();
  runApp(const BorneoApp());
}

class BorneoApp extends StatelessWidget {
  const BorneoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Borneo Smart Farming',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: latarAbu,
        colorScheme: ColorScheme.fromSeed(seedColor: utamaHijau, primary: utamaHijau),
        fontFamily: 'Roboto',
      ),
      // Mengatur Halaman Login sebagai tampilan awal
      home: const LoginScreen(), 
    );
  }
}