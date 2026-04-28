import 'package:flutter/material.dart';
import 'package:eco_collect/components/buttons/reusable_button.dart';
import 'package:eco_collect/utils/kloading.dart';
import 'package:eco_collect/constants/kenums.dart';

class GeoCampusQuizScreen extends StatefulWidget {
  const GeoCampusQuizScreen({super.key});

  @override
  State<GeoCampusQuizScreen> createState() => _GeoCampusQuizScreenState();
}

class _GeoCampusQuizScreenState extends State<GeoCampusQuizScreen> {
  int _currentQuestionIndex = 0;
  
  final List<Map<String, dynamic>> _quizzes = [
    {
      'question': 'Which plant is native to the Mediterranean campus region?',
      'options': ['Oak Tree', 'Olive Tree', 'Pine Tree', 'Cherry Blossom'],
      'answer': 'Olive Tree'
    },
    {
      'question': 'What is the main SDG targeted by planting local vegetation?',
      'options': ['SDG 4: Education', 'SDG 15: Life on Land', 'SDG 1: No Poverty'],
      'answer': 'SDG 15: Life on Land'
    }
  ];

  void _submitAnswer(String selectedOption) {
    if (selectedOption == _quizzes[_currentQuestionIndex]['answer']) {
      KLoadingToast.showCustomDialog(
        message: 'Correct! +20 XP',
        toastType: KenumToastType.success,
      );
    } else {
      KLoadingToast.showCustomDialog(
        message: 'Incorrect! Try again tomorrow.',
        toastType: KenumToastType.error,
      );
    }
    
    setState(() {
      if (_currentQuestionIndex < _quizzes.length - 1) {
        _currentQuestionIndex++;
      } else {
         // Finished quiz
         Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final quiz = _quizzes[_currentQuestionIndex];
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Sustainability Quiz'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Question ${_currentQuestionIndex + 1}/${_quizzes.length}',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Text(
              quiz['question'],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ...(quiz['options'] as List<String>).map((option) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 15.0),
                child: ReusableButton(
                  label: option,
                  mainAxisAlignment: MainAxisAlignment.center,
                  onTap: () => _submitAnswer(option),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
