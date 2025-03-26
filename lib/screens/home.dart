import 'dart:math';
import 'package:flutter/material.dart';
import 'package:studybuddy_app/screens/profile_screen.dart';
import 'package:studybuddy_app/screens/rooms_screen.dart';
import 'package:studybuddy_app/screens/resources_screen.dart';
import 'package:studybuddy_app/screens/career_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileScreen(),
                fullscreenDialog: true,
              ),
            ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: Duration(milliseconds: 300),
          builder: (context, double value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, (1 - value) * 20),
                child: child,
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Alex!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[900],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Ready for a focused session?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _quickActions.length,
        separatorBuilder: (_, __) => SizedBox(width: 12),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Feedback.forTap(context);
              _showQuickActionDialog(context, _quickActions[index]['label']);
            },
            child: Container(
              width: 80,
              decoration: BoxDecoration(
                color: _quickActions[index]['color'] as Color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_quickActions[index]['icon'] as IconData, 
                      size: 28, color: Colors.grey[800]),
                  SizedBox(height: 8),
                  Text(
                    _quickActions[index]['label'] as String,
                    style: TextStyle(
                      fontSize: 12,
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
    );
  }

  void _showQuickActionDialog(BuildContext context, String action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action Selected'),
        content: Text('This would open the $action feature in a full implementation.'),
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
        Text(
          'TODAY\'S TASKS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[500],
            letterSpacing: 1,
          ),
        ),
        SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              ..._tasks.map((task) {
                return Dismissible(
                  key: Key(task['id'].toString()),
                  background: Container(
                    color: Colors.red[100],
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.only(left: 20),
                    child: Icon(Icons.delete, color: Colors.red),
                  ),
                  secondaryBackground: Container(
                    color: Colors.green[100],
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 20),
                    child: Icon(Icons.archive, color: Colors.green),
                  ),
                  onDismissed: (direction) {
                    setState(() {
                      _tasks.removeWhere((t) => t['id'] == task['id']);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Task ${task['title']} dismissed'),
                        action: SnackBarAction(
                          label: 'UNDO',
                          onPressed: () {
                            setState(() {
                              _tasks.add(task);
                            });
                          },
                        ),
                      ),
                    );
                  },
                  child: ListTile(
                    leading: Checkbox(
                      value: task['completed'] as bool,
                      onChanged: (value) {
                        setState(() {
                          task['completed'] = value;
                          if (value == true) {
                            _currentStreak++;
                            _studyHours += 2;
                            _efficiency = (_efficiency + 0.01).clamp(0.0, 1.0);
                          }
                        });
                      },
                      activeColor: Colors.blue[400],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    title: Text(
                      task['title'] as String,
                      style: TextStyle(
                        decoration: task['completed'] as bool 
                            ? TextDecoration.lineThrough 
                            : null,
                        color: task['completed'] as bool 
                            ? Colors.grey[400] 
                            : Colors.grey[800],
                      ),
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: Colors.grey[400], size: 20),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'delete') {
                          setState(() {
                            _tasks.removeWhere((t) => t['id'] == task['id']);
                          });
                        }
                      },
                    ),
                  ),
                );
              }).toList(),
              ListTile(
                leading: Icon(Icons.add, color: Colors.blue[400], size: 20),
                title: Text(
                  'Add new task',
                  style: TextStyle(
                    color: Colors.blue[400],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () => _showAddTaskDialog(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    TextEditingController _taskController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Task'),
        content: TextField(
          controller: _taskController,
          decoration: InputDecoration(
            hintText: 'Enter task description',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
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
          'STUDY PROGRESS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[500],
            letterSpacing: 1,
          ),
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(
                height: 150,
                child: CustomPaint(
                  painter: ProgressChartPainter(
                    streak: _currentStreak.toDouble(),
                    hours: _studyHours.toDouble(),
                    efficiency: _efficiency,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem('$_currentStreak', 'Day Streak', Colors.orange[100]),
                  _buildStatItem('${_studyHours}h', 'This Week', Colors.green[100]),
                  _buildStatItem('${(_efficiency * 100).toStringAsFixed(0)}%', 'Efficiency', Colors.blue[100]),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String value, String label, Color? color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.grey[800],
            ),
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
    );
  }

  Widget _buildReminderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'UPCOMING EXAMS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500],
                letterSpacing: 1,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'View All',
                style: TextStyle(
                  color: Colors.blue[400],
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        ..._reminders.map((reminder) {
          return Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder['course'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        reminder['date'] as String,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  reminder['daysLeft'] as String,
                  style: TextStyle(
                    color: Colors.orange[400],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildMotivationSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'DAILY MOTIVATION',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500],
                letterSpacing: 1,
              ),
            ),
            IconButton(
              icon: _isRefreshingQuote
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.refresh, size: 18, color: Colors.grey[500]),
              onPressed: () {
                if (_isRefreshingQuote) return;
                
                setState(() => _isRefreshingQuote = true);
                Feedback.forTap(context);
                
                Future.delayed(Duration(seconds: 1), () {
                  final randomQuote = _quotes..shuffle();
                  final quoteString = randomQuote.first;
                  final quoteParts = quoteString.split(' - ');
                  setState(() {
                    _motivationalQuote = quoteParts[0];
                    _quoteAuthor = quoteParts.length > 1 ? '- ${quoteParts[1]}' : '';
                    _isRefreshingQuote = false;
                  });
                });
              },
            ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                _motivationalQuote,
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[800],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                _quoteAuthor,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ProgressChartPainter extends CustomPainter {
  final double streak;
  final double hours;
  final double efficiency;

  ProgressChartPainter({
    required this.streak,
    required this.hours,
    required this.efficiency,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3;
    
    final bgPaint = Paint()
      ..color = Colors.grey[200]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    
    canvas.drawCircle(center, radius, bgPaint);
    
    final streakPaint = Paint()
      ..color = Colors.orange[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    
    final streakSweep = 2 * pi * (streak / 30).clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      streakSweep,
      false,
      streakPaint,
    );
    
    final hoursPaint = Paint()
      ..color = Colors.green[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    
    final hoursSweep = 2 * pi * (hours / 40).clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2 + streakSweep + 0.1,
      hoursSweep,
      false,
      hoursPaint,
    );
    
    final efficiencyPaint = Paint()
      ..color = Colors.blue[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    
    final efficiencySweep = 2 * pi * efficiency.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2 + streakSweep + hoursSweep + 0.2,
      efficiencySweep,
      false,
      efficiencyPaint,
    );
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Progress',
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}