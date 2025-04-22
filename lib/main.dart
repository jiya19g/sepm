import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:studybuddy_app/main_wrapper.dart';
import 'package:studybuddy_app/screens/WelcomeScreen.dart';
import 'package:studybuddy_app/screens/loginscree.dart';
import 'package:studybuddy_app/screens/register_screen.dart';
import 'package:studybuddy_app/service/study_session_service.dart';

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
        '/': (context) =>  WelcomeScreen(),
        '/login': (context) =>  LoginScreen(),
        '/main': (context) =>  StudySessionWrapper(child: MainWrapper()),
        '/register': (context) =>  RegisterScreen(),
      },
    );
  }
}

class StudySessionWrapper extends StatefulWidget {
  final Widget child;
  const StudySessionWrapper({super.key, required this.child});

  @override
  State<StudySessionWrapper> createState() => _StudySessionWrapperState();
}

class _StudySessionWrapperState extends State<StudySessionWrapper> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Study session indicator banner
          if (StudySessionService().isStudying)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.green[100],
              child: Row(
                children: [
                  const Icon(Icons.timer, color: Colors.green),
                  const SizedBox(width: 8),
                  const Text('Study session in progress'),
                  const Spacer(),
                  Text('${StudySessionService().sessionMinutes} min'),
                ],
              ),
            ),
          // Main content
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}