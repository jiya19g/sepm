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

  // UI data
  bool _isRefreshingQuote = false;
  String _motivationalQuote = '"Success is the sum of small efforts, repeated day in and day out."';
  String _quoteAuthor = '- Robert Collier';
  final List<Map<String, dynamic>> _quickActions = [
    {'icon': Icons.video_library, 'label': 'Lectures', 'color': Colors.blue[100]},
    {'icon': Icons.article, 'label': 'Notes', 'color': Colors.green[100]},
    {'icon': Icons.quiz, 'label': 'Quizzes', 'color': Colors.orange[100]},
    {'icon': Icons.group, 'label': 'Groups', 'color': Colors.purple[100]},
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
  }

  @override
  void dispose() {
    _studyTimer?.cancel();
    super.dispose();
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

  Future<void> _loadStudyMetrics() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final metricsDoc = await _firestore.collection('users').doc(user.uid).collection('metrics').doc('study').get();
    if (metricsDoc.exists) {
      final data = metricsDoc.data()!;
      setState(() {
        _currentStreak = data['currentStreak'] ?? 0;
        _totalStudyMinutes = data['totalStudyMinutes'] ?? 0;
        _lastStudyDate = data['lastStudyDate']?.toDate();
        _completedTasksCount = data['completedTasksCount'] ?? 0;
        _totalTasksCount = data['totalTasksCount'] ?? 1;
        _efficiencyScore = _completedTasksCount / _totalTasksCount;
      });
    }
  }

  void _startStudySession() {
    setState(() {
      _isStudying = true;
      _studySessionStart = DateTime.now();
      _sessionMinutes = 0;
      
      _studyTimer = Timer.periodic(Duration(minutes: 1), (timer) {
        setState(() {
          _sessionMinutes++;
          _totalStudyMinutes++;
        });
      });
    });
  }

  Future<void> _endStudySession() async {
    final user = _auth.currentUser;
    if (user == null || !_isStudying) return;

    _studyTimer?.cancel();
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));

    int newStreak = _currentStreak;
    if (_lastStudyDate == null) {
      newStreak = 1;
    } else {
      final lastStudyDay = DateTime(_lastStudyDate!.year, _lastStudyDate!.month, _lastStudyDate!.day);
      if (lastStudyDay.isAtSameMomentAs(today)) {
        // No streak change
      } else if (lastStudyDay.isAtSameMomentAs(yesterday)) {
        newStreak++;
      } else {
        newStreak = 1;
      }
    }

    setState(() {
      _isStudying = false;
      _currentStreak = newStreak;
      _lastStudyDate = now;
    });

    await _firestore.collection('users').doc(user.uid).collection('metrics').doc('study').set({
      'currentStreak': newStreak,
      'totalStudyMinutes': _totalStudyMinutes,
      'lastStudyDate': now,
      'completedTasksCount': _completedTasksCount,
      'totalTasksCount': _totalTasksCount,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _showSessionSummary(_sessionMinutes);
  }

  void _showSessionSummary(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Study Session Completed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('You studied for $hours hours and $remainingMinutes minutes.'),
            SizedBox(height: 16),
            if (_currentStreak > 1) Text('🔥 Current streak: $_currentStreak days'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildStudySessionButton() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _isStudying ? Colors.red : Colors.green,
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _isStudying ? _endStudySession : _startStudySession,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_isStudying ? Icons.stop : Icons.play_arrow),
            SizedBox(width: 8),
            Text(
              _isStudying ? 'END STUDY SESSION' : 'START STUDY SESSION',
              style: TextStyle(fontSize: 16),
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
              value: '${(_efficiencyScore * 100).toStringAsFixed(0)}%',
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
      content = 'Efficiency: ${(_efficiencyScore * 100).toStringAsFixed(0)}%\n\n'
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
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
          ),
          itemCount: _quickActions.length,
          itemBuilder: (context, index) {
            final action = _quickActions[index];
            return InkWell(
              onTap: () => _showQuickActionDialog(context, action['label']),
              child: Container(
                decoration: BoxDecoration(
                  color: action['color'],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
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

  void _showQuickActionDialog(BuildContext context, String action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Quick Action: $action'),
        content: Text('This feature is coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
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
                  _efficiencyScore = _completedTasksCount / max(1, _totalTasksCount);
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
                        if (taskData['completed']) {
                          _completedTasksCount = max(0, _completedTasksCount - 1);
                        }
                        _totalTasksCount = max(0, _totalTasksCount - 1);
                        _efficiencyScore = _completedTasksCount / max(1, _totalTasksCount);
                        
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
                  _efficiencyScore = _completedTasksCount / _totalTasksCount;
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
      _efficiencyScore = _completedTasksCount / max(1, _totalTasksCount);
    });

    await _updateFirebaseMetrics();
  }

  Future<void> _updateFirebaseMetrics() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).collection('metrics').doc('study').set({
      'currentStreak': _currentStreak,
      'totalStudyMinutes': _totalStudyMinutes,
      'lastStudyDate': _lastStudyDate,
      'completedTasksCount': _completedTasksCount,
      'totalTasksCount': _totalTasksCount,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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