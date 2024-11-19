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
import 'results_screen.dart';

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
  late List<String> _currentPossibleAnswers;
  late String _currentCorrectAnswer;

  @override
  void initState() {
    super.initState();
  }

String? _errorMessage;

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
  
  void _generateNewQuestion() {
      _currentQuestion = _challenges[_currentProblem]['problem'];
      _currentCorrectAnswer = _calculateCorrectAnswer();
    _currentPossibleAnswers = _generatePossibleAnswers();
    
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
            mutation StartGame($_difficulty: String!) {
              startGame(difficulty: $_difficulty) {
                id
                challenges {
                  id
                  problem
                }
              }
            }
          ''',
          variables: {
            'difficulty': _difficulty,
          },
        ),
      );

      final response = await restOperation.response;

            if (response.data == null) {
        throw Exception('No data received from server');
      }

      final data = json.decode(response.data!);
      final game = data['startGame'];

      if (data == null) {
        throw Exception('Invalid game data received');
      }

      if (game != null) {
        setState(() {
          _gameStarted = true;
          _currentProblem = 0;
          _score = 0;
          _timeLeft = 30;
          _gameId = game['id'];
          _challenges = List<Map<String, dynamic>>.from(game['challenges']);
          _generateNewQuestion();
        });
        _getNextProblem();
        _startTimer();
      } else {
        print('Failed to start game: No game data received');
      }
    } on ApiException catch (e) {
      _showError('Network error: ${e.message}');
      safePrint('Failed to start game: ${e.message}');
    } on FormatException catch (e) {
      _showError('Error processing server response: ${e.message}');
      safePrint('JSON parsing error: $e');
    } on Exception catch (e) {
      _showError('Unexpected error: ${e.toString()}');
      safePrint('Unexpected error: $e');
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          // When timer hits 0, submit the current answer or an empty answer if none selected
          _answerController.text =
              _answerController.text.isEmpty ? "" : _answerController.text;
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
    // Calculate correct answer
    String correctAnswer = _currentCorrectAnswer;
    int correct = int.parse(correctAnswer);

    // Generate 4 wrong answers within a reasonable range
    final random = math.Random();
    Set<String> answers = {correctAnswer}; // Use Set to ensure uniqueness

    // Generate wrong answers based on operation type
    while (answers.length < 6) {
      int wrongAnswer;
      // Extract operation from question
      String operation = _currentQuestion.split(' ')[1];

      switch (operation) {
        case '+':
        case '-':
          wrongAnswer = correct + (random.nextInt(21) - 10); // Range: ±10
          break;
        case '*':
          wrongAnswer = correct + (random.nextInt(11) - 5); // Range: ±5
          break;
        case '/':
          wrongAnswer = correct + (random.nextInt(5) - 2); // Range: ±2
          break;
        default:
          wrongAnswer = correct + (random.nextInt(11) - 5);
      }

      // Only add if it's different from correct answer and makes sense
      if (wrongAnswer != correct && wrongAnswer > 0) {
        answers.add(wrongAnswer.toString());
      }
    }

    // Convert Set back to List and shuffle
    List<String> answersList = answers.toList();

    // Shuffle the answers to randomize the correct answer position
    answersList.shuffle();

    return answersList;
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

  List<Map<String, dynamic>> _gameResults = [];

  Future<void> _checkAnswer() async {
    if (_answerController.text.isEmpty) {
      _showError('Please select an answer');
      return;
    }
    // Stop the timer while processing the answer
    _timer.cancel();

    int userAnswer = int.tryParse(_answerController.text) ?? -1;

    try {
      // Get the current challenge ID from the challenges array using the currentProblem index
      String challengeId = _challenges[_currentProblem]['id'];
      // log the parameters of the graphql query
      print('Current _gameId: $_gameId');
      print('Challenge ID: $challengeId');
      print('User answer: $userAnswer');

      final restOperation = Amplify.API.mutate(
        request: GraphQLRequest<String>(
          document: '''
          mutation SubmitChallenge($_gameId: ID!, $challengeId: ID!, $userAnswer: Int!) {
            submitChallenge(gameId: $_gameId, challengeId: $challengeId, answer: $userAnswer)
          }
        ''',
          variables: {
            'gameId': _gameId,
            'challengeId': challengeId, // Use the extracted challengeId
            'answer': userAnswer,
          },
        ),
      );

      final response = await restOperation.response;
      final data = json.decode(response.data!);
      final bool isCorrect = data['submitChallenge'] ?? false;

      // Store the result for final display
      _gameResults.add({
        'question': _currentQuestion,
        'userAnswer': userAnswer.toString(),
        'correctAnswer': _currentCorrectAnswer,
        'isCorrect': isCorrect,
      });

      setState(() {
        if (isCorrect) {
          _score++;
        }
      });

      _answerController.clear();

      // Move to next problem immediately after answer is processed
      await Future.delayed(const Duration(milliseconds: 100));

      if (_currentProblem < _challenges.length - 1) {
        setState(() {
          _currentProblem++;
          _gameStarted = true; // Re-enable game
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
    // not in app notification that the game ended
    print('Game ended. Score: $_score');

    //show notification bar in app that t he game ended
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Game ended. Score: $_score'),
        duration: const Duration(seconds: 3),
      ),
    );

    // Get player name
    String playerName = await _getPlayerName();
    try {
      // Ensure we're using mounted check before any setState calls
      if (!mounted) return;

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
      if (response.data == null) {
        throw Exception('No game result data received');
      }

      final data = json.decode(response.data!);
      final gameResult = data['getGameResult'];

      if (gameResult != null && mounted) {
        // Add a small delay to ensure proper navigation
        await Future.delayed(const Duration(milliseconds: 300));
        _showGameResult(gameResult);
      } else {
        print('Failed to get game result: No data received');
        // Show error message to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to load game results. Please try again.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } on ApiException catch (e) {
      _showError('Network error while fetching results: ${e.message}');
      safePrint('Failed to get game result: ${e.message}');
    } on FormatException catch (e) {
      _showError('Error processing game results: ${e.message}');
      safePrint('JSON parsing error: $e');
    } on Exception catch (e) {
      _showError('Unexpected error: ${e.toString()}');
      safePrint('Unexpected error: $e');
    }
  }

  void _showGameResult(Map<String, dynamic> gameResult) {
    setState(() {
      _gameStarted = false;
    });

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Game Results'),
            automaticallyImplyLeading: false,
          ),
          body: ResultsScreen(
            totalChallenges: gameResult['totalChallenges'],
            correctAnswers: gameResult['correctAnswers'],
            challengeResults: _gameResults,
            onPlayAgain: () {
              Navigator.of(context).pop();
              _startGame();
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Column(children: [
          Container(
            padding: const EdgeInsets.all(5.0),
            child: Image.asset(
              'web/jhs.png',
              height: 100,
            ),
          ),
          Expanded(
            child: Center(
              child: _gameStarted
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text('Score: $_score',
                            style: const TextStyle(fontSize: 18)),
                        const SizedBox(height: 20),
                        Text('Time left: $_timeLeft seconds',
                            style: const TextStyle(fontSize: 18)),
                        const SizedBox(height: 20),
                        GamePlayArea(
                          question:
                              'Problem ${_currentProblem + 1}: $_currentQuestion',
                          possibleAnswers: _currentPossibleAnswers,
                          correctAnswer: _currentCorrectAnswer,
                          onAnswerSubmitted: (isCorrect, selectedAnswer) async {
                            _answerController.text = selectedAnswer;
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
          )
        ]));
  }
}
