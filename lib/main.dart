import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Add this import
import 'package:studybuddy_app/main_wrapper.dart';
import 'package:studybuddy_app/screens/WelcomeScreen.dart';
import 'package:studybuddy_app/screens/loginscree.dart';
import 'package:studybuddy_app/screens/register_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize Supabase
  try {
  await Supabase.initialize(
    url: 'https://xfatedjzzwyvcfcpvepu.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhmYXRlZGp6end5dmNmY3B2ZXB1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDM2OTI5ODAsImV4cCI6MjA1OTI2ODk4MH0.dTlxBDFvZYA3SGmH8MSzD2ZS5rKpiFdE4hugqn1mw4U',
  );
} catch (e) {
  print('Supabase initialization error: $e');
  // You might want to show an error screen or retry logic here
}
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StudyBuddy',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => WelcomeScreen(),
        '/login': (context) => LoginScreen(),
        '/main': (context) => MainWrapper(),
        '/register': (context) => RegisterScreen(),
      },
    );
  }
}