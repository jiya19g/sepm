// study_session_service.dart
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudySessionService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Timer? _studyTimer;
  int _sessionMinutes = 0;
  DateTime? _studySessionStart;
  bool _isStudying = false;
  
  // Singleton pattern
  static final StudySessionService _instance = StudySessionService._internal();
  factory StudySessionService() => _instance;
  StudySessionService._internal();
  
  bool get isStudying => _isStudying;
  int get sessionMinutes => _sessionMinutes;
  
  void startStudySession() {
    if (_isStudying) return;
    
    _isStudying = true;
    _studySessionStart = DateTime.now();
    _sessionMinutes = 0;
    
    _studyTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      _sessionMinutes++;
      _updateTotalStudyTime();
    });
  }
  
  Future<void> endStudySession() async {
    _studyTimer?.cancel();
    _isStudying = false;
    await _updateStreak();
    _sessionMinutes = 0;
  }
  
  Future<void> _updateTotalStudyTime() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    await _firestore.collection('users').doc(user.uid).collection('metrics').doc('study').set({
      'totalStudyMinutes': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
  
  Future<void> _updateStreak() async {
    final user = _auth.currentUser;
    if (user == null || _studySessionStart == null) return;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    
    final metricsDoc = await _firestore.collection('users').doc(user.uid).collection('metrics').doc('study').get();
    final lastStudyDate = metricsDoc.data()?['lastStudyDate']?.toDate();
    
    int newStreak = metricsDoc.data()?['currentStreak'] ?? 0;
    if (lastStudyDate == null) {
      newStreak = 1;
    } else {
      final lastStudyDay = DateTime(lastStudyDate.year, lastStudyDate.month, lastStudyDate.day);
      if (lastStudyDay.isAtSameMomentAs(today)) {
        // No change
      } else if (lastStudyDay.isAtSameMomentAs(yesterday)) {
        newStreak++;
      } else {
        newStreak = 1;
      }
    }
    
    await _firestore.collection('users').doc(user.uid).collection('metrics').doc('study').set({
      'currentStreak': newStreak,
      'lastStudyDate': now,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}