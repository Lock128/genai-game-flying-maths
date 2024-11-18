import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_authenticator/amplify_authenticator.dart';
import 'dart:convert';
import 'dart:async';

import 'amplifyconfiguration.dart';

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

  Future<void> _checkAnswer() async {
    int userAnswer = int.tryParse(_answerController.text) ?? -1;
    // log _challenges 
    print(_challenges);
    print(_currentProblem);

    try {
      var challengeId;
      final restOperation = Amplify.API.mutate(
        request: GraphQLRequest<String>(
          document: '''
            mutation SubmitChallenge($_gameId: ID!, $challengeId: ID!, $userAnswer: Int!) {
              submitChallenge(gameId: $_gameId, challengeId: $challengeId, answer: $userAnswer)
            }
          ''',
          variables: {
            'gameId': _gameId,
            'challengeId': _challenges[_currentProblem]['id'],
            'answer': userAnswer,
          },
        ),
      );

      final response = await restOperation.response;
      final data = json.decode(response.data!);
      final bool isCorrect = data['submitChallenge'] ?? false;

      setState(() {
        if (isCorrect) _score++;
      });

      _answerController.clear();

      if (_currentProblem < _challenges.length - 1) {
        setState(() {
          _currentProblem++;
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
                  Text(
                    'Problem ${_currentProblem + 1}: $_currentQuestion',
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _answerController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Enter your answer',
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _checkAnswer,
                    child: const Text('Submit'),
                  ),
                  const SizedBox(height: 20),
                  Text('Score: $_score', style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 20),
                  Text('Time left: $_timeLeft seconds',
                      style: const TextStyle(fontSize: 18)),
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
