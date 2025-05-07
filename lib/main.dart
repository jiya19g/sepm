import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:studybuddy_app/main_wrapper.dart';
import 'package:studybuddy_app/screens/WelcomeScreen.dart';
import 'package:studybuddy_app/screens/loginscree.dart';
import 'package:studybuddy_app/screens/register_screen.dart';
import 'package:studybuddy_app/screens/chatbot_screen.dart';
import 'package:studybuddy_app/screens/quizzes_screen.dart';
import 'package:studybuddy_app/screens/lectures_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
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
        '/chatbot': (context) => ChatbotScreen(),
        '/quizzes': (context) => QuizzesScreen(),
        '/lectures': (context) => LecturesScreen(),
      },
    );
  }
  
}
