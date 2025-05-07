import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:studybuddy_app/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _mounted = true;

@override
void dispose() {
  _mounted = false;
  _studyTimer?.cancel();
  super.dispose();
}
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _userName = 'User';
  
  // Study metrics
  int _currentStreak = 0;
  int _totalStudyMinutes = 0;
  double _efficiencyScore = 0.0;
  int _completedTasksCount = 0;
  int _totalTasksCount = 0;
  DateTime? _lastStudyDate;
  
  // Study session tracking
  bool _isStudying = false;
  DateTime? _studySessionStart;
  Timer? _studyTimer;
  int _sessionMinutes = 0;
  bool _streakUpdatedToday = false;
  StreamSubscription? _studySessionSubscription;
  StreamSubscription? _metricsSubscription;

  // UI data
  bool _isRefreshingQuote = false;
  String _motivationalQuote = '"Success is the sum of small efforts, repeated day in and day out."';
  String _quoteAuthor = '- Robert Collier';
  final List<Map<String, dynamic>> _quickActions = [
    {'icon': Icons.video_library, 'label': 'Lectures', 'color': Colors.blue[100], 'route': '/lectures'},
    {'icon': Icons.quiz, 'label': 'Quizzes', 'color': Colors.orange[100], 'route': '/quizzes'},
    {'icon': Icons.chat, 'label': 'Chatbot', 'color': Colors.purple[100], 'route': '/chatbot'},
  ];
  final List<String> _quotes = [
    '"The expert in anything was once a beginner." - Helen Hayes',
    '"Don\'t watch the clock; do what it does. Keep going." - Sam Levenson',
    '"Success is no accident. It is hard work, perseverance, learning, studying, sacrifice and most of all, love of what you are doing." - Pelé',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _setupRealTimeListeners();
    
    // Check streak daily at midnight
    Timer.periodic(Duration(minutes: 5), (timer) {
      final now = DateTime.now();
      if (now.hour == 0 && now.minute >= 0 && now.minute < 5) {
        setState(() {
          _streakUpdatedToday = false;
        });
        _updateFirebaseMetrics();
      }
    });
  }


  @override
  void dispose() {
    _studyTimer?.cancel();
    _studySessionSubscription?.cancel();
    _metricsSubscription?.cancel();
    super.dispose();
  }


  void _setupRealTimeListeners() {
    final user = _auth.currentUser;
    if (user == null) return;

    // Listen to metrics changes
    _metricsSubscription?.cancel();
    _metricsSubscription = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('metrics')
        .doc('study')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data()!;
        setState(() {
          _currentStreak = data['currentStreak'] ?? 0;
          _totalStudyMinutes = data['totalStudyMinutes'] ?? 0;
          _lastStudyDate = data['lastStudyDate']?.toDate();
          _completedTasksCount = data['completedTasksCount'] ?? 0;
          _totalTasksCount = data['totalTasksCount'] ?? 0;
          _streakUpdatedToday = data['streakUpdatedToday'] ?? false;
          _efficiencyScore = _calculateEfficiency();
        });
      }
    });

    // Listen to active session changes
    _studySessionSubscription?.cancel();
    _studySessionSubscription = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('activeSessions')
        .doc('current')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data()!;
        final startTime = (data['startTime'] as Timestamp).toDate();
        final now = DateTime.now();
        
        if (!_isStudying) {
          setState(() {
            _isStudying = true;
            _studySessionStart = startTime;
            _sessionMinutes = now.difference(startTime).inMinutes;
          });
          _startTimer();
        }
      } else if (_isStudying) {
        _endStudySession();
      }
    });
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          _userName = userDoc.data()?['name'] ?? 'User';
        });
      }
    }
  }

  double _calculateEfficiency() {
    if (_totalTasksCount <= 0) return 0.0;
    double efficiency = (_completedTasksCount / _totalTasksCount) * 100;
    return efficiency.clamp(0.0, 100.0);
  }

  void _showSessionSummary(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Text('Session Completed', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Great job studying today!', style: TextStyle(fontSize: 16)),
            SizedBox(height: 16),
            _buildSummaryRow(Icons.timer, 'Duration:', 
                '$hours ${hours == 1 ? 'hour' : 'hours'} $remainingMinutes minutes'),
            SizedBox(height: 8),
            _buildSummaryRow(Icons.today, 'Date:', 
                DateFormat('MMMM d, y').format(today)),
            SizedBox(height: 8),
            if (_currentStreak > 0)
              _buildSummaryRow(Icons.local_fire_department, 'Current streak:', 
                  '$_currentStreak ${_currentStreak == 1 ? 'day' : 'days'}'),
            SizedBox(height: 16),
            Text('Keep up the good work!', 
                style: TextStyle(fontStyle: FontStyle.italic)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).primaryColor,
            ),
            child: Text('DISMISS'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        SizedBox(width: 8),
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(width: 8),
        Text(value),
      ],
    );
  }

  void _startTimer() {
    _studyTimer?.cancel();
    _studyTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      if (_isStudying) {
        setState(() {
          _sessionMinutes++;
          _totalStudyMinutes++;
        });
        _updateFirebaseMetrics();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _startStudySession() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final now = DateTime.now();


    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('activeSessions')
          .doc('current')
          .set({
        'startTime': Timestamp.fromDate(now),
        'lastUpdated': Timestamp.now(),
      });

      setState(() {
        _isStudying = true;
        _studySessionStart = now;
        _sessionMinutes = 0;
      });

      _startTimer();
    } catch (e) {
      print('Error starting study session: $e');
    }
  }

 void _startStudySession() {
  // Cancel any existing timer (safety check)
  _studyTimer?.cancel();
  
  final now = DateTime.now();

  setState(() {
    _isStudying = true;
    _studySessionStart = now;
    _sessionMinutes = 0;
    
    // Create new timer
    _studyTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      // Check if still studying
      if (_isStudying) {
        setState(() {
          _sessionMinutes++;
          _totalStudyMinutes++;
        });
      } else {
        timer.cancel(); // Safety measure
      }
    });
  });
}


  Future<void> _endStudySession() async {
    final user = _auth.currentUser;
    if (user == null || !_isStudying) return;


    try {
      _studyTimer?.cancel();
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Delete active session
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('activeSessions')
          .doc('current')
          .delete();

      // Save session to history
      if (_studySessionStart != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('studySessions')
            .add({
          'startTime': Timestamp.fromDate(_studySessionStart!),
          'endTime': Timestamp.now(),
          'durationMinutes': _sessionMinutes,
          'date': Timestamp.fromDate(today),

  // Cancel timer immediately
  _studyTimer?.cancel();
  
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // Update state first before any async operations
  setState(() {
    _isStudying = false; // This must come first
    _totalStudyMinutes += _sessionMinutes;
  });

  // Streak update logic
  if (_lastStudyDate == null) {
    // First ever study session
    setState(() {
      _currentStreak = 1;
      _streakUpdatedToday = true;
      _lastStudyDate = now;
    });
  } else {
    final lastStudyDay = DateTime(
      _lastStudyDate!.year,
      _lastStudyDate!.month,
      _lastStudyDate!.day,
    );
    
    if (lastStudyDay.isBefore(today)) {
      // New day - check if consecutive
      if (lastStudyDay.isAtSameMomentAs(today.subtract(Duration(days: 1)))) {
        // Consecutive day
        setState(() {
          _currentStreak++;
          _streakUpdatedToday = true;
          _lastStudyDate = now;

        });
      }

      // Update streak
      if (_lastStudyDate == null) {
        setState(() {
          _currentStreak = 1;
          _streakUpdatedToday = true;
          _lastStudyDate = now;
        });
      } else {
        final lastStudyDay = DateTime(
          _lastStudyDate!.year,
          _lastStudyDate!.month,
          _lastStudyDate!.day,
        );
        
        if (lastStudyDay.isBefore(today)) {
          if (lastStudyDay.isAtSameMomentAs(today.subtract(Duration(days: 1)))) {
            setState(() {
              _currentStreak++;
              _streakUpdatedToday = true;
              _lastStudyDate = now;
            });
          } else {
            setState(() {
              _currentStreak = 1;
              _streakUpdatedToday = true;
              _lastStudyDate = now;
            });
          }
        }
      }

    }
  }

  // Save to Firestore
  await _updateFirebaseMetrics();
  
  // Debug print
  _printCurrentState();
  
  // Show summary
  if (mounted) {
    _showSessionSummary(_sessionMinutes);
  }
}
Future<void> _updateStreakAndStudyTime() async {
  final user = _auth.currentUser;
  if (user == null) return;


      setState(() {
        _isStudying = false;
        _totalStudyMinutes += _sessionMinutes;
      });

      await _updateFirebaseMetrics();
      _showSessionSummary(_sessionMinutes);

    } catch (e) {
      print('Error ending study session: $e');
    }
  }

  Future<void> _updateFirebaseMetrics() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('metrics')
          .doc('study')
          .set({
        'currentStreak': _currentStreak,
        'totalStudyMinutes': _totalStudyMinutes,
        'lastStudyDate': _lastStudyDate != null ? Timestamp.fromDate(_lastStudyDate!) : null,
        'completedTasksCount': _completedTasksCount,
        'totalTasksCount': _totalTasksCount,
        'streakUpdatedToday': _streakUpdatedToday,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error saving to Firestore: $e');
    }
  }

  Widget _buildStudySessionButton() {

    return Container(
      margin: EdgeInsets.symmetric(vertical: 16),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: _isStudying ? Colors.red[400] : Theme.of(context).primaryColor,
          padding: EdgeInsets.symmetric(vertical: 24, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 4,
          shadowColor: _isStudying ? Colors.red[100] : Theme.of(context).primaryColor.withOpacity(0.3),
        ),
        onPressed: _isStudying ? _endStudySession : _startStudySession,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_isStudying ? Icons.stop_circle_outlined : Icons.play_circle_fill_outlined, size: 32),
            SizedBox(width: 12),
            Text(
              _isStudying ? 'STOP SESSION' : 'START STUDYING',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),

  return Container(
    margin: EdgeInsets.symmetric(vertical: 16),
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: _isStudying ? Colors.red[400] : Theme.of(context).primaryColor,
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        shadowColor: _isStudying ? Colors.red[100] : Theme.of(context).primaryColor.withOpacity(0.3),
      ),
      onPressed: () async {
        if (_isStudying) {
          await _endStudySession();
        } else {
          _startStudySession();
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_isStudying ? Icons.stop : Icons.play_arrow, size: 28),
          SizedBox(width: 12),
          Text(
            _isStudying ? 'STOP SESSION' : 'START STUDYING',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,

            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStudySessionButton(),
        Text(
          'Your Progress',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              icon: Icons.local_fire_department,
              value: _currentStreak.toString(),
              label: 'Day Streak',
              color: Colors.orange,
            ),
            _buildStatItem(
              icon: Icons.access_time,
              value: '${(_totalStudyMinutes / 60).floor()}h ${_totalStudyMinutes % 60}m',
              label: 'Study Time',
              color: Colors.blue,
            ),
            _buildStatItem(
              icon: Icons.trending_up,
              value: '${_efficiencyScore.toStringAsFixed(0)}%',
              label: 'Efficiency',
              color: Colors.green,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () => _showMetricInfoDialog(label),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMetricInfoDialog(String metric) {
    String content = '';
    String title = metric;
    
    if (metric == 'Day Streak') {
      content = 'Your current study streak is $_currentStreak days.\n\n'
                'Maintain your streak by studying every day!';
    } else if (metric == 'Study Time') {
      content = 'Total study time: ${(_totalStudyMinutes / 60).floor()} hours '
                '${_totalStudyMinutes % 60} minutes.\n\n'
                'Tracked through study sessions.';
    } else if (metric == 'Efficiency') {
      content = 'Efficiency: ${_efficiencyScore.toStringAsFixed(0)}%\n\n'
                'Based on tasks completed ($_completedTasksCount out of $_totalTasksCount)';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back,',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4),
          Text(
            _userName,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          if (_isStudying) ...[
            SizedBox(height: 8),
            Text(
              'Currently studying...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.0,
          ),
          itemCount: _quickActions.length,
          itemBuilder: (context, index) {
            final action = _quickActions[index];
            return InkWell(
              onTap: () => Navigator.pushNamed(context, action['route']),
              child: Container(
                decoration: BoxDecoration(
                  color: action['color'],
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      action['icon'],
                      size: 40,
                      color: Colors.grey[800],
                    ),
                    SizedBox(height: 12),
                    Text(
                      action['label'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTodoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Today\'s Tasks',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () => _showAddTaskDialog(context),
            ),
          ],
        ),
        SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('users')
              .doc(_auth.currentUser?.uid)
              .collection('tasks')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
            
            final tasks = snapshot.data!.docs;
            if (tasks.isEmpty) {
              return Center(child: Text('No tasks yet. Add one to get started!'));
            }

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_totalTasksCount != tasks.length) {
                setState(() {
                  _totalTasksCount = tasks.length;
                  _completedTasksCount = tasks.where((t) => (t.data() as Map<String, dynamic>)['completed'] == true).length;
                  _efficiencyScore = _calculateEfficiency();
                });
                _updateFirebaseMetrics();
              }
            });

            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                final taskData = task.data() as Map<String, dynamic>;
                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: Checkbox(
                      value: taskData['completed'] ?? false,
                      onChanged: (value) {
                        if (value != null) {
                          _firestore
                              .collection('users')
                              .doc(_auth.currentUser?.uid)
                              .collection('tasks')
                              .doc(task.id)
                              .update({'completed': value});
                          _updateTaskCompletion(value);
                        }
                      },
                    ),
                    title: Text(
                      taskData['title'],
                      style: TextStyle(
                        decoration: taskData['completed'] 
                            ? TextDecoration.lineThrough 
                            : null,
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          if (taskData['completed']) {
                            _completedTasksCount = max(0, _completedTasksCount - 1);
                          }
                          _totalTasksCount = max(0, _totalTasksCount - 1);
                          _efficiencyScore = _calculateEfficiency();
                        });
                        
                        _firestore
                            .collection('users')
                            .doc(_auth.currentUser?.uid)
                            .collection('tasks')
                            .doc(task.id)
                            .delete();
                        
                        _updateFirebaseMetrics();
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final TextEditingController _taskController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Task'),
        content: TextField(
          controller: _taskController,
          decoration: InputDecoration(
            hintText: 'Enter task description',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_taskController.text.isNotEmpty) {
                _firestore
                    .collection('users')
                    .doc(_auth.currentUser?.uid)
                    .collection('tasks')
                    .add({
                  'title': _taskController.text,
                  'completed': false,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                setState(() {
                  _totalTasksCount++;
                  _efficiencyScore = _calculateEfficiency();
                });
                _updateFirebaseMetrics();
                Navigator.pop(context);
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateTaskCompletion(bool isCompleted) async {
    setState(() {
      if (isCompleted) {
        _completedTasksCount++;
      } else {
        _completedTasksCount = max(0, _completedTasksCount - 1);
      }
      _efficiencyScore = _calculateEfficiency();
    });

    await _updateFirebaseMetrics();
  }


Future<void> _updateFirebaseMetrics() async {
  if (!_mounted) return;
  final user = _auth.currentUser;
  if (user == null) return;

  try {
    await _firestore.collection('users').doc(user.uid).collection('metrics').doc('study').set({
      'currentStreak': _currentStreak,
      'totalStudyMinutes': _totalStudyMinutes,
      'lastStudyDate': _lastStudyDate != null ? Timestamp.fromDate(_lastStudyDate!) : null,
      'completedTasksCount': _completedTasksCount,
      'totalTasksCount': _totalTasksCount,
      'streakUpdatedToday': _streakUpdatedToday,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  } catch (e) {
    print('Error updating metrics: $e');
    if (_mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save session data')),
      );
    }
  }
}

  Widget _buildReminderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upcoming Deadlines',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () => _showAddDeadlineDialog(context),
            ),
          ],
        ),
        SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('users')
              .doc(_auth.currentUser?.uid)
              .collection('deadlines')
              .orderBy('dueDate')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
            
            final deadlines = snapshot.data!.docs;
            if (deadlines.isEmpty) {
              return Center(child: Text('No deadlines yet. Add one to stay organized!'));
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: deadlines.length,
              itemBuilder: (context, index) {
                final deadline = deadlines[index];
                final deadlineData = deadline.data() as Map<String, dynamic>;
                final dueDate = (deadlineData['dueDate'] as Timestamp).toDate();
                final daysLeft = dueDate.difference(DateTime.now()).inDays;

                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            deadlineData['title'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            DateFormat('MMM dd, yyyy').format(dueDate),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        daysLeft > 0 
                            ? '$daysLeft ${daysLeft == 1 ? 'day' : 'days'} left'
                            : 'Due today',
                        style: TextStyle(
                          fontSize: 14,
                          color: daysLeft <= 3 ? Colors.red[400] : Colors.green[400],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  void _showAddDeadlineDialog(BuildContext context) {
    final TextEditingController _titleController = TextEditingController();
    DateTime _selectedDate = DateTime.now();
    TimeOfDay _selectedTime = TimeOfDay.now();

    Future<void> _selectDate(BuildContext context) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime.now(),
        lastDate: DateTime(2101),
      );
      if (picked != null && picked != _selectedDate) {
        setState(() {
          _selectedDate = picked;
        });
      }
    }

    Future<void> _selectTime(BuildContext context) async {
      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: _selectedTime,
      );
      if (picked != null && picked != _selectedTime) {
        setState(() {
          _selectedTime = picked;
        });
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Add New Deadline'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Title (e.g., Math Final Exam)',
                    ),
                  ),
                  SizedBox(height: 16),
                  ListTile(
                    title: Text('Date: ${DateFormat('MMM dd, yyyy').format(_selectedDate)}'),
                    trailing: Icon(Icons.calendar_today),
                    onTap: () => _selectDate(context),
                  ),
                  ListTile(
                    title: Text('Time: ${_selectedTime.format(context)}'),
                    trailing: Icon(Icons.access_time),
                    onTap: () => _selectTime(context),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_titleController.text.isNotEmpty) {
                    final dueDateTime = DateTime(
                      _selectedDate.year,
                      _selectedDate.month,
                      _selectedDate.day,
                      _selectedTime.hour,
                      _selectedTime.minute,
                    );
                    
                    _firestore
                        .collection('users')
                        .doc(_auth.currentUser?.uid)
                        .collection('deadlines')
                        .add({
                      'title': _titleController.text,
                      'dueDate': Timestamp.fromDate(dueDateTime),
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    
                    Navigator.pop(context);
                  }
                },
                child: Text('Add Deadline'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMotivationSection() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _motivationalQuote,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
          SizedBox(height: 12),
          Text(
            _quoteAuthor,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _isRefreshingQuote
                ? null
                : () {
                    setState(() {
                      _isRefreshingQuote = true;
                      final random = Random();
                      final newQuote = _quotes[random.nextInt(_quotes.length)];
                      final parts = newQuote.split(' - ');
                      _motivationalQuote = parts[0];
                      _quoteAuthor = '- ${parts[1]}';
                      Future.delayed(Duration(seconds: 1), () {
                        setState(() {
                          _isRefreshingQuote = false;
                        });
                      });
                    });
                  },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh),
                SizedBox(width: 8),
                Text('New Quote'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'StudyBuddy',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.person, color: Colors.grey[800], size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuickActions(),
            SizedBox(height: 32),
            _buildTodoSection(),
            SizedBox(height: 32),
            _buildProgressSection(),
            SizedBox(height: 32),
            _buildReminderSection(),
            SizedBox(height: 32),
            _buildMotivationSection(),
          ],
        ),
      ),
    );
  }
}