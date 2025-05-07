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
    // Don't cancel timer here - it should continue running
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

  // UI data
  bool _isRefreshingQuote = false;
  String _motivationalQuote = '"Success is the sum of small efforts, repeated day in and day out."';
  String _quoteAuthor = '- Robert Collier';
  final List<Map<String, dynamic>> _quickActions = [
    {'icon': Icons.video_library, 'label': 'Lectures', 'color': Colors.blue[100], 'route': '/lectures'},
    {'icon': Icons.smart_toy, 'label': 'Chatbot', 'color': Colors.green[100], 'route': '/chatbot'},
    {'icon': Icons.quiz, 'label': 'Quizzes', 'color': Colors.orange[100], 'route': '/quizzes'},
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
    _loadStudyMetrics();
    
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

  Future<void> _checkActiveStudySession() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final sessionDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('studySessions')
          .doc('active')
          .get();

      if (sessionDoc.exists) {
        final data = sessionDoc.data()!;
        final startTime = data['startTime']?.toDate();
        
        if (startTime != null) {
          setState(() {
            _isStudying = true;
            _studySessionStart = startTime;
            _sessionMinutes = DateTime.now().difference(startTime).inMinutes;
          });
          
          // Resume timer
          _startStudyTimer();
        }
      }
    } catch (e) {
      print('Error checking active session: $e');
    }
  }

  void _startStudySession() {
    final now = DateTime.now();
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() {
      _isStudying = true;
      _studySessionStart = now;
      _sessionMinutes = 0;
      
      // Set streak to 1 if this is the first study session of the day
      if (_currentStreak == 0) {
        _currentStreak = 1;
        _streakUpdatedToday = true;
        _lastStudyDate = now;
      }
    });

    // Save active session to Firestore
    _firestore
        .collection('users')
        .doc(user.uid)
        .collection('studySessions')
        .doc('active')
        .set({
      'startTime': now,
      'lastUpdated': now,
    });

    // Immediately update metrics to ensure streak is saved
    _updateFirebaseMetrics();
    _startStudyTimer();
  }

  void _startStudyTimer() {
    _studyTimer?.cancel();
    _studyTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      if (_isStudying) {
        setState(() {
          _sessionMinutes++;
        });
        // Update Firestore every minute
        _updateFirebaseMetrics();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _endStudySession() async {
    final user = _auth.currentUser;
    if (user == null || !_isStudying) return;

    // Cancel timer
    _studyTimer?.cancel();
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Update state - accumulate study time instead of resetting
    setState(() {
      _isStudying = false;
      _totalStudyMinutes += _sessionMinutes;
    });

    // Save completed session
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('studySessions')
        .add({
      'startTime': _studySessionStart,
      'endTime': now,
      'durationMinutes': _sessionMinutes,
      'date': today,
    });

    // Remove active session
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('studySessions')
        .doc('active')
        .delete();

    // Update last study date
    setState(() {
      _lastStudyDate = now;
      _streakUpdatedToday = true;
    });

    await _updateFirebaseMetrics();
    
    if (mounted) {
      _showSessionSummary(_sessionMinutes);
    }
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

  Future<void> _loadStudyMetrics() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Load metrics from Firestore
      final metricsDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('metrics')
          .doc('study')
          .get();

      if (metricsDoc.exists) {
        final data = metricsDoc.data()!;
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final lastStudyDate = data['lastStudyDate']?.toDate();
        
        // Check if we have a study session today
        bool hasStudyToday = false;
        if (lastStudyDate != null) {
          final lastStudyDay = DateTime(
            lastStudyDate.year,
            lastStudyDate.month,
            lastStudyDate.day,
          );
          hasStudyToday = lastStudyDay.isAtSameMomentAs(today);
        }

        setState(() {
          // If we have a study session today, keep the streak
          _currentStreak = hasStudyToday ? (data['currentStreak'] ?? 1) : 0;
          _totalStudyMinutes = data['totalStudyMinutes'] ?? 0;
          _lastStudyDate = lastStudyDate;
          _completedTasksCount = data['completedTasksCount'] ?? 0;
          _totalTasksCount = data['totalTasksCount'] ?? 0;
          _streakUpdatedToday = data['streakUpdatedToday'] ?? false;
          _efficiencyScore = _calculateEfficiency();
        });
      }

      // Load active session if exists
      final activeSessionDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('studySessions')
          .doc('active')
          .get();

      if (activeSessionDoc.exists) {
        final sessionData = activeSessionDoc.data()!;
        final startTime = sessionData['startTime']?.toDate();
        
        if (startTime != null) {
          setState(() {
            _isStudying = true;
            _studySessionStart = startTime;
            _sessionMinutes = DateTime.now().difference(startTime).inMinutes;
            // If we're studying, ensure streak is at least 1
            if (_currentStreak == 0) {
              _currentStreak = 1;
              _streakUpdatedToday = true;
              _lastStudyDate = DateTime.now();
            }
          });
          
          // Resume timer
          _startStudyTimer();
        }
      }

      // Calculate total study time from all sessions
      final sessionsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('studySessions')
          .where('endTime', isNull: false)  // Only completed sessions
          .get();

      int totalMinutes = 0;
      for (var doc in sessionsSnapshot.docs) {
        final data = doc.data();
        totalMinutes += data['durationMinutes'] as int? ?? 0;
      }

      // Add current session minutes if studying
      if (_isStudying) {
        totalMinutes += _sessionMinutes;
      }

      setState(() {
        _totalStudyMinutes = totalMinutes;
      });

      // Update Firestore with latest metrics
      await _updateFirebaseMetrics();
    } catch (e) {
      print('Error loading metrics: $e');
    }
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

  Widget _buildStudySessionButton() {
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
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
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
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _quickActions.map((action) {
            return GestureDetector(
              onTap: () => Navigator.pushNamed(context, action['route']),
              child: Container(
                width: 100,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: action['color'],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      action['icon'],
                      size: 32,
                      color: Colors.grey[800],
                    ),
                    SizedBox(height: 8),
                    Text(
                      action['label'],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
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
      // Calculate total study time including current session
      int totalMinutes = _totalStudyMinutes;
      if (_isStudying) {
        totalMinutes += _sessionMinutes;
      }

      // Create a batch write to ensure all updates are atomic
      final batch = _firestore.batch();
      final metricsRef = _firestore.collection('users').doc(user.uid).collection('metrics').doc('study');
      
      batch.set(metricsRef, {
        'currentStreak': _currentStreak,
        'totalStudyMinutes': totalMinutes,
        'lastStudyDate': _lastStudyDate != null ? Timestamp.fromDate(_lastStudyDate!) : null,
        'completedTasksCount': _completedTasksCount,
        'totalTasksCount': _totalTasksCount,
        'streakUpdatedToday': _streakUpdatedToday,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update active session if studying
      if (_isStudying && _studySessionStart != null) {
        final activeSessionRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('studySessions')
            .doc('active');
            
        batch.set(activeSessionRef, {
          'startTime': _studySessionStart,
          'lastUpdated': FieldValue.serverTimestamp(),
          'currentMinutes': _sessionMinutes,
        });
      }

      // Commit the batch
      await batch.commit();
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
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            _motivationalQuote,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            _quoteAuthor,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
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

  void _printCurrentState() {
    print('''
    Current State:
    - Streak: $_currentStreak
    - Study Minutes: $_totalStudyMinutes
    - Last Study: $_lastStudyDate
    - Streak Updated Today: $_streakUpdatedToday
    ''');
  }

  void _checkFirestoreData() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('metrics')
        .doc('study')
        .get();
    
    print('Firestore Data: ${doc.data()}');
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
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.person, color: Colors.grey[800]),
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
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(),
            SizedBox(height: 24),
            _buildQuickActions(),
            SizedBox(height: 24),
            _buildTodoSection(),
            SizedBox(height: 24),
            _buildProgressSection(),
            SizedBox(height: 24),
            _buildReminderSection(),
            SizedBox(height: 24),
            _buildMotivationSection(),
          ],
        ),
      ),
    );
  }
}