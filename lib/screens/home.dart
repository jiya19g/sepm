import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:studybuddy_app/screens/profile_screen.dart';
import 'package:studybuddy_app/screens/rooms_screen.dart';
import 'package:studybuddy_app/screens/resources_screen.dart';
import 'package:studybuddy_app/screens/career_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _userName = 'Alex'; // Default user name
  String _userEmail = ''; // Will be updated with Firebase user email
  String _profilePicture = ''; // Default profile picture
  
  int _currentStreak = 5;
  int _studyHours = 12;
  double _efficiency = 0.87;
  bool _isRefreshingQuote = false;
  String _motivationalQuote = '"Success is the sum of small efforts, repeated day in and day out."';
  String _quoteAuthor = '- Robert Collier';

  final List<Map<String, dynamic>> _tasks = [
    {'title': 'Complete math assignment', 'completed': false, 'id': 1},
    {'title': 'Review biology notes', 'completed': true, 'id': 2},
    {'title': 'Prepare for physics quiz', 'completed': false, 'id': 3},
  ];

  final List<Map<String, dynamic>> _quickActions = [
    {'icon': Icons.video_library, 'label': 'Lectures', 'color': Colors.blue[100]},
    {'icon': Icons.article, 'label': 'Notes', 'color': Colors.green[100]},
    {'icon': Icons.quiz, 'label': 'Quizzes', 'color': Colors.orange[100]},
    {'icon': Icons.group, 'label': 'Groups', 'color': Colors.purple[100]},
  ];

  final List<Map<String, dynamic>> _reminders = [
    {'course': 'Mathematics', 'date': 'May 15', 'daysLeft': '3 days left'},
    {'course': 'Physics', 'date': 'May 18', 'daysLeft': '6 days left'},
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
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _userEmail = user.email ?? '';
        _userName = user.displayName ?? 'User';
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
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
            icon: Icon(Icons.logout, color: Colors.grey[800]),
            onPressed: _signOut,
          ),
          IconButton(
            icon: Icon(Icons.person, color: Colors.grey[800]),
            onPressed: () async {
              final userDetails = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(),
                  fullscreenDialog: true,
                ),
              );

              if (userDetails != null) {
                setState(() {
                  _userName = userDetails['name'];
                  _userEmail = userDetails['email'];
                  _profilePicture = userDetails['profilePicture'];
                });
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(context),
            SizedBox(height: 24),
            _buildQuickActions(context),
            SizedBox(height: 24),
            _buildTodoSection(),
            SizedBox(height: 24),
            _buildProgressSection(),
            SizedBox(height: 24),
            _buildReminderSection(),
            SizedBox(height: 24),
            _buildMotivationSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
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
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
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
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _tasks.length,
          itemBuilder: (context, index) {
            final task = _tasks[index];
            return Container(
              margin: EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                leading: Checkbox(
                  value: task['completed'],
                  onChanged: (value) {
                    setState(() {
                      _tasks[index]['completed'] = value;
                    });
                  },
                ),
                title: Text(
                  task['title'],
                  style: TextStyle(
                    decoration: task['completed'] ? TextDecoration.lineThrough : null,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    setState(() {
                      _tasks.removeAt(index);
                    });
                  },
                ),
              ),
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
                setState(() {
                  _tasks.add({
                    'title': _taskController.text,
                    'completed': false,
                    'id': DateTime.now().millisecondsSinceEpoch,
                  });
                });
                Navigator.pop(context);
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              value: _studyHours.toString(),
              label: 'Study Hours',
              color: Colors.blue,
            ),
            _buildStatItem(
              icon: Icons.trending_up,
              value: '${(_efficiency * 100).round()}%',
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
    return Container(
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
    );
  }

  Widget _buildReminderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Deadlines',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _reminders.length,
          itemBuilder: (context, index) {
            final reminder = _reminders[index];
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
                        reminder['course'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        reminder['date'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    reminder['daysLeft'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red[400],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMotivationSection(BuildContext context) {
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
}

class ProgressChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(size.width * 0.2, size.height * 0.7);
    path.lineTo(size.width * 0.4, size.height * 0.8);
    path.lineTo(size.width * 0.6, size.height * 0.3);
    path.lineTo(size.width * 0.8, size.height * 0.5);
    path.lineTo(size.width, size.height * 0.2);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}