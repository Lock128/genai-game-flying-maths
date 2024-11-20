import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'utils/math_utils.dart';

class ResultsScreen extends StatelessWidget {
  final int totalChallenges;
  final int correctAnswers;
  final List<Map<String, dynamic>> challengeResults;
  final int score;
  final VoidCallback onPlayAgain;
  final VoidCallback onMainPage;
  final String playerName;

  const ResultsScreen({
    Key? key,
    required this.totalChallenges,
    required this.correctAnswers,
    required this.challengeResults,
    required this.score,
    required this.onPlayAgain, 
    required this.onMainPage,
    required this.playerName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          AppLocalizations.of(context)!.gameResults,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 20),
        Text(
          AppLocalizations.of(context)!.playerName(playerName),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(
          AppLocalizations.of(context)!.finalScore(
            score.toString(),
            totalChallenges.toString(),
          ),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            itemCount: challengeResults.length,
            itemBuilder: (context, index) {
              final result = challengeResults[index];
              final question = result['question'];
              final correctAnswer = calculateCorrectAnswer(question);
              return ListTile(
                title: Text(AppLocalizations.of(context)!.problem(
                  (index + 1).toString(),
                  question,
                )),
                subtitle: Text(
                  '${AppLocalizations.of(context)!.yourAnswer(result['userAnswer'])} (${result['isCorrect'] ? AppLocalizations.of(context)!.correct : AppLocalizations.of(context)!.wrong}) \n${AppLocalizations.of(context)!.correctAnswer(correctAnswer)}'
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
          child: Text(AppLocalizations.of(context)!.playAgain),
        ),
        const SizedBox(height: 15),
        ElevatedButton(
          onPressed: onMainPage,
          child: Text(AppLocalizations.of(context)!.home),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}