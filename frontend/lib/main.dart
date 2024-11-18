import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_authenticator/amplify_authenticator.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;

import 'amplifyconfiguration.dart';
import 'game_components.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _configureAmplify();
  runApp(const MyApp());
}

Future<void> _configureAmplify() async {
  try {
    final api = AmplifyAPI();
    final auth = AmplifyAuthCognito();
    await Amplify.addPlugins([api, auth]);
    await Amplify.configure(amplifyconfig);
  } catch (e) {
    print('An error occurred while configuring Amplify: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Authenticator(
      child: MaterialApp(
        builder: Authenticator.builder(),
        title: 'Flying Maths',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const MyHomePage(title: 'Flying Maths'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _gameStarted = false;
  int _currentProblem = 0;
  int _score = 0;
  String _currentQuestion = '';
  String _difficulty = 'medium';
  final TextEditingController _answerController = TextEditingController();
  late Timer _timer;
  int _timeLeft = 30;
  String _gameId = '';
  List<Map<String, dynamic>> _challenges = [];

  @override
  void initState() {
    super.initState();
  }

  Future<String> _getPlayerName() async {
    String? name;
    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter your name'),
          content: TextField(
            autofocus: true,
            onChanged: (value) {
              name = value;
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
    return name?.trim() ?? 'Anonymous';
  }

  Future<void> _startGame() async {
    try {
      final restOperation = Amplify.API.mutate(
        request: GraphQLRequest<String>(
          document: '''
            mutation StartGame {
              startGame {
                id
                challenges {
                  id
                  problem
                }
              }
            }
          ''',
        ),
      );

      final response = await restOperation.response;
      final data = json.decode(response.data!);
      final game = data['startGame'];

      if (game != null) {
        setState(() {
          _gameStarted = true;
          _currentProblem = 0;
          _score = 0;
          _timeLeft = 30;
          _gameId = game['id'];
          _challenges = List<Map<String, dynamic>>.from(game['challenges']);
        });
        _getNextProblem();
        _startTimer();
      } else {
        print('Failed to start game: No game data received');
      }
    } on ApiException catch (e) {
      print('Failed to start game: ${e.message}');
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _checkAnswer();
        }
      });
    });
  }

  void _resetTimer() {
    _timer.cancel();
    setState(() {
      _timeLeft = 30;
    });
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    _answerController.dispose();
    super.dispose();
  }

  void _getNextProblem() {
    if (_currentProblem < _challenges.length) {
      setState(() {
        _currentQuestion = _challenges[_currentProblem]['problem'];
      });
    } else {
      _endGame();
    }
  }

  List<String> _generatePossibleAnswers() {
    // Parse the current question to get the numbers
    final parts = _currentQuestion.split(' ');
    int num1 = int.parse(parts[0]);
    int num2 = int.parse(parts[2]);
    
    // Calculate correct answer
    String correctAnswer = _calculateCorrectAnswer();
    int correct = int.parse(correctAnswer);
    
    // Generate 3 wrong answers within a reasonable range
    final random = math.Random();
    List<String> answers = [];
    
    // Add correct answer first
    answers.add(correctAnswer);
    
    // Add three wrong answers in fixed positions
    while (answers.length < 4) {
      int wrongAnswer = correct;
      // Ensure we generate a unique wrong answer
      do {
        wrongAnswer = correct + (random.nextInt(11) - 5);
      } while (wrongAnswer == correct || answers.contains(wrongAnswer.toString()));
      answers.add(wrongAnswer.toString());
    }
    
    return answers;
  }

  String _calculateCorrectAnswer() {
    // Parse the current question to get the numbers and operator
    final parts = _currentQuestion.split(' ');
    int num1 = int.parse(parts[0]);
    String operator = parts[1];
    int num2 = int.parse(parts[2]);
    
    // Calculate result based on operator
    switch (operator) {
      case '+':
        return (num1 + num2).toString();
      case '-':
        return (num1 - num2).toString();
      case '*':
        return (num1 * num2).toString();
      case '/':
        return (num1 ~/ num2).toString();
      default:
        return '0';
    }
  }

  Future<void> _checkAnswer() async {
    if (_answerController.text.isEmpty) return;
    
    // Stop the timer while processing the answer
    _timer.cancel();
    if (!_answerController.text.isEmpty) {
      setState(() {
        _gameStarted = false;  // Temporarily pause game to prevent multiple submissions
      });
    }
    int userAnswer = int.tryParse(_answerController.text) ?? -1;
  
  // Debug logging to see the state
  print('Current problem index: $_currentProblem');
  print('Challenges: $_challenges');

  try {
    // Get the current challenge ID from the challenges array using the currentProblem index
    String challengeId = _challenges[_currentProblem]['id'];
    // log the parameters of the graphql query
    print('Challenge ID: $challengeId');
    print('User answer: $userAnswer');
    print('Current _gameId: $_gameId');

    final restOperation = Amplify.API.mutate(
      request: GraphQLRequest<String>(
        document: '''
          mutation SubmitChallenge {
            submitChallenge(gameId: $_gameId, challengeId: $challengeId, answer: $userAnswer)
          }
        ''',
        variables: {
          'gameId': _gameId,
          'challengeId': challengeId,  // Use the extracted challengeId
          'answer': userAnswer,
        },
      ),
    );

    final response = await restOperation.response;
    print('Raw response data: ${response.data}');
    final data = json.decode(response.data!);
    print('Decoded response data: $data');
    final bool isCorrect = data['submitChallenge'] ?? false;
    print('Is correct: $isCorrect');
    setState(() {
      if (isCorrect) {
        _score++;
      }
    });

    _answerController.clear();
    
    // Move to next problem immediately after answer is processed
    await Future.delayed(Duration(milliseconds: 100));

    if (_currentProblem < _challenges.length - 1) {
      setState(() {
        _currentProblem++;
        _gameStarted = true;  // Re-enable game
      });
      _getNextProblem();
      _resetTimer();
    } else {
      _endGame();
    }
  } on ApiException catch (e) {
    print('Failed to submit answer: ${e.message}');
  }
}


  Future<void> _endGame() async {
    _timer.cancel();
    try {
      final restOperation = Amplify.API.query(
        request: GraphQLRequest<String>(
          document: '''
            query GetGameResult($_gameId: ID!) {
              getGameResult(gameId: $_gameId) {
                totalChallenges
                correctAnswers
                completionTime
              }
            }
          ''',
          variables: {
            'gameId': _gameId,
          },
        ),
      );

      final response = await restOperation.response;
      final data = json.decode(response.data!);
      final gameResult = data['getGameResult'];

      if (gameResult != null) {
        _showGameResult(gameResult);
      } else {
        print('Failed to get game result: No data received');
      }
    } on ApiException catch (e) {
      print('Failed to get game result: ${e.message}');
    }
  }

  void _showGameResult(Map<String, dynamic> gameResult) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Game Result'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Challenges: ${gameResult['totalChallenges']}'),
              Text('Correct Answers: ${gameResult['correctAnswers']}'),
              Text('Completion Time: ${gameResult['completionTime']} seconds'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Play Again'),
              onPressed: () {
                Navigator.of(context).pop();
                _startGame();
              },
            ),
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _gameStarted = false;
                });
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: _gameStarted
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text('Score: $_score', style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 20),
                  Text('Time left: $_timeLeft seconds',
                      style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 20),
                  GamePlayArea(
                    question: 'Problem ${_currentProblem + 1}: $_currentQuestion',
                    possibleAnswers: _generatePossibleAnswers(),
                    correctAnswer: _calculateCorrectAnswer(),
                    onAnswerSubmitted: (isCorrect, selectedAnswer) async {
                      print('Answer submitted: $isCorrect');
                      setState(() {
                        _answerController.text = selectedAnswer;
                      });
                      await _checkAnswer();
                    },
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text('Select difficulty:',
                      style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 20),
                  DropdownButton<String>(
                    value: _difficulty,
                    onChanged: (String? newValue) {
                      setState(() {
                        _difficulty = newValue!;
                      });
                    },
                    items: <String>['easy', 'medium', 'hard']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _startGame,
                    child: const Text('Start Game'),
                  ),
                ],
              ),
      ),
    );
  }
}
