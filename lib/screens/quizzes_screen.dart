import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class QuizzesScreen extends StatefulWidget {
  @override
  _QuizzesScreenState createState() => _QuizzesScreenState();
}

class _QuizzesScreenState extends State<QuizzesScreen> {
  final TextEditingController _topicController = TextEditingController();
  final String _apiKey = 'AIzaSyDjOzsu8PNtsBMn35Vob9U65Q3GjPEz0so';
  bool _isLoading = false;
  List<QuizQuestion> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _quizCompleted = false;

  Future<void> _generateQuiz() async {
    if (_topicController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _questions = [];
      _currentQuestionIndex = 0;
      _score = 0;
      _quizCompleted = false;
    });

    try {
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{
            'parts': [{
              'text': '''Create a quiz about ${_topicController.text} with 5 multiple choice questions. 
              Each question should have 4 options and one correct answer.
              Format the response as a JSON array of objects with this exact structure:
              [
                {
                  "question": "Question text here",
                  "options": ["Option A", "Option B", "Option C", "Option D"],
                  "correctAnswer": "Correct option text here"
                }
              ]
              Make sure the response is valid JSON and follows this exact format.'''
            }]
          }]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse = data['candidates'][0]['content']['parts'][0]['text'];
        
        // Clean the response text to ensure it's valid JSON
        String cleanJson = aiResponse.trim();
        if (cleanJson.startsWith('```json')) {
          cleanJson = cleanJson.substring(7);
        }
        if (cleanJson.endsWith('```')) {
          cleanJson = cleanJson.substring(0, cleanJson.length - 3);
        }
        cleanJson = cleanJson.trim();

        try {
          final List<dynamic> questionsJson = jsonDecode(cleanJson);
          if (questionsJson.isEmpty) {
            throw Exception('No questions generated');
          }

          setState(() {
            _questions = questionsJson.map((q) => QuizQuestion.fromJson(q)).toList();
            _isLoading = false;
          });
        } catch (e) {
          print('JSON parsing error: $e');
          print('Raw response: $cleanJson');
          throw Exception('Invalid quiz format received');
        }
      } else {
        print('API Error: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to generate quiz: ${response.statusCode}');
      }
    } catch (e) {
      print('Error generating quiz: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating quiz. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _checkAnswer(String selectedAnswer) {
    if (_questions[_currentQuestionIndex].correctAnswer == selectedAnswer) {
      setState(() {
        _score++;
      });
    }

    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      setState(() {
        _quizCompleted = true;
      });
    }
  }

  void _resetQuiz() {
    setState(() {
      _questions = [];
      _currentQuestionIndex = 0;
      _score = 0;
      _quizCompleted = false;
      _topicController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Quizzes',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _questions.isEmpty && !_isLoading
          ? _buildTopicInput()
          : _isLoading
              ? _buildLoadingScreen()
              : _quizCompleted
                  ? _buildResultsScreen()
                  : _buildQuizScreen(),
    );
  }

  Widget _buildTopicInput() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.quiz,
            size: 80,
            color: Colors.orange[100],
          ),
          SizedBox(height: 32),
          Text(
            'Generate a Quiz',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Enter a topic to generate a quiz',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 32),
          TextField(
            controller: _topicController,
            decoration: InputDecoration(
              hintText: 'Enter topic (e.g., Mathematics, History)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _generateQuiz,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Generate Quiz',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Generating your quiz...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizScreen() {
    final question = _questions[_currentQuestionIndex];
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _questions.length,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          SizedBox(height: 24),
          Text(
            'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 16),
          Text(
            question.question,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 24),
          ...question.options.map((option) => Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: ElevatedButton(
              onPressed: () => _checkAnswer(option),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.white,
                foregroundColor: Colors.grey[800],
                elevation: 2,
              ),
              child: Text(
                option,
                style: TextStyle(fontSize: 16),
              ),
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildResultsScreen() {
    final percentage = (_score / _questions.length) * 100;
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            percentage >= 70 ? Icons.emoji_events : Icons.school,
            size: 80,
            color: percentage >= 70 ? Colors.amber : Colors.blue,
          ),
          SizedBox(height: 24),
          Text(
            'Quiz Completed!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Your Score: $_score/${_questions.length}',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: percentage >= 70 ? Colors.green : Colors.orange,
            ),
          ),
          SizedBox(height: 32),
          ElevatedButton(
            onPressed: _resetQuiz,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Try Another Quiz',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final String correctAnswer;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json['question'],
      options: List<String>.from(json['options']),
      correctAnswer: json['correctAnswer'],
    );
  }
} 