import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Supabase con tus credenciales de la nube
  await Supabase.initialize(
    url: 'https://pahuzsesucuvgqkihtxu.supabase.co',
    anonKey: 'sb_publishable_JOUqJJ_NTbFfhCTmPdPgEw_Y1TtdKzy',
  );

  runApp(const KdramaApp());
}
class KdramaApp extends StatelessWidget {
  const KdramaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'K-Drama App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA), // Un tono gris muy suave y limpio de fondo
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFF1493),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF1493),
          primary: const Color(0xFFFF1493),
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}