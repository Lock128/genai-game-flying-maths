import 'package:flutter/material.dart';

class ResultsScreen extends StatelessWidget {
  final int totalChallenges;
  final int correctAnswers;
  final List<Map<String, dynamic>> challengeResults;
  final VoidCallback onPlayAgain;

  const ResultsScreen({
    Key? key,
    required this.totalChallenges,
    required this.correctAnswers,
    required this.challengeResults,
    required this.onPlayAgain,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Game Results',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 20),
        Text(
          'Score: $correctAnswers / $totalChallenges',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            itemCount: challengeResults.length,
            itemBuilder: (context, index) {
              final result = challengeResults[index];
              return ListTile(
                title: Text('Problem ${index + 1}: ${result['question']}'),
                subtitle: Text(
                  'Your answer: ${result['userAnswer']} (${result['isCorrect'] ? 'Correct' : 'Wrong'}) \nCorrect answer: ${result['correctAnswer']}'
                ),
                leading: Icon(
                  result['isCorrect'] ? Icons.check_circle : Icons.cancel,
                  color: result['isCorrect'] ? Colors.green : Colors.red,
                ),
              );
            },
          ),
        ),
        ElevatedButton(
          onPressed: onPlayAgain,
          child: const Text('Play Again'),
        ),
      ],
    );
  }
}