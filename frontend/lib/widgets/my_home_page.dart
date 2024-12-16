import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'dart:convert';
import 'package:flag/flag.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:convert';
import 'dart:async';

import '../game_components.dart';
import '../results_screen.dart';
import '../utils/math_utils.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.onLanguageChanged})
      : super(key: key);

  final void Function(Locale) onLanguageChanged;

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
  late Locale _currentLocale = Locale('de');
  List<Map<String, dynamic>> _gameResults = [];

  String _playerName = 'Anonymous';
  bool playerNameSet = false;

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
    _currentCorrectAnswer = calculateCorrectAnswer(_currentQuestion);
    _currentPossibleAnswers = generatePossibleAnswers();
  }

  Future<String> _getPlayerName() async {
    String? name;
    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.enterName),
          content: TextField(
            autofocus: true,
            onChanged: (value) {
              name = value;
            },
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.ok),
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
      if (_playerName == 'Anonymous' && !playerNameSet) {
        _playerName = await _getPlayerName();
        playerNameSet = true;
      }
      final restOperation = Amplify.API.mutate(
        request: GraphQLRequest<String>(document: '''
            mutation StartGame {
              startGame(difficulty: "$_difficulty") {
                id
                challenges {
                  id
                  problem
                  correctAnswer
                }
              }
            }
          '''),
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
          _gameResults = [];
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
        _currentCorrectAnswer = calculateCorrectAnswer(_currentQuestion);
        _currentPossibleAnswers = generatePossibleAnswers();
      });
    } else {
      _endGame();
    }
  }

  Future<void> _checkAnswer() async {
    if (_answerController.text.isEmpty) {
      _showError(AppLocalizations.of(context)!.selectAnswer);
      return;
    }
    _timer.cancel();

    int userAnswer = int.tryParse(_answerController.text) ?? -1;

    try {
      String challengeId = _challenges[_currentProblem]['id'];
      print('Current _gameId: $_gameId');
      print('Challenge ID: $challengeId');
      print('User answer: $userAnswer');

      final restOperation = Amplify.API.mutate(
        request: GraphQLRequest<String>(document: '''
          mutation SubmitChallenge {
            submitChallenge(gameId: "$_gameId", challengeId: "$challengeId", answer: $userAnswer)
          }
        '''),
      );

      final response = await restOperation.response;
      final data = json.decode(response.data!);
      final bool isCorrect = data['submitChallenge'] ?? false;

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

      await Future.delayed(const Duration(milliseconds: 100));

      if (_currentProblem < _challenges.length - 1) {
        setState(() {
          _currentProblem++;
          _gameStarted = true;
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
    print('Game ended. Score: $_score');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.gameEnded(_score)),
        duration: const Duration(seconds: 3),
      ),
    );

    try {
      if (!mounted) return;

      final restOperation = Amplify.API.query(
        request: GraphQLRequest<String>(document: '''
            query GetGameResult {
              getGameResult(gameId: "$_gameId") {
                totalChallenges
                correctAnswers
                completionTime
              }
            }
          '''),
      );

      final response = await restOperation.response;
      if (response.data == null) {
        throw Exception('No game result data received');
      }

      final data = json.decode(response.data!);
      final gameResult = data['getGameResult'];

      if (gameResult != null && mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
        _showGameResult(gameResult);
      } else {
        print('Failed to get game result: No data received');
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
            title: Text(AppLocalizations.of(context)!.appTitle),
            automaticallyImplyLeading: false,
          ),
          body: ResultsScreen(
            totalChallenges: gameResult['totalChallenges'],
            correctAnswers: gameResult['correctAnswers'],
            challengeResults: _gameResults,
            score: _score,
            playerName: _playerName,
            onPlayAgain: () {
              Navigator.of(context).pop();
              _startGame();
            },
            onMainPage: () {
              Navigator.of(context).pop();
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
          title: Text(AppLocalizations.of(context)!.appTitle),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: DropdownButton<String>(
                underline: const SizedBox(),
                icon: const Icon(Icons.language, color: Colors.white),
                dropdownColor: Colors.blue,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    Locale newLocale = Locale(newValue);
                    Localizations.override(
                      context: context,
                      locale: newLocale,
                      child: widget,
                    );
                    setState(() {
                      _currentLocale = newLocale;
                    });
                    widget.onLanguageChanged(_currentLocale);
                  }
                },
                items: const [
                  DropdownMenuItem(
                    value: 'de',
                    child: Flag.fromCode(FlagsCode.DE, height: 20, width: 30),
                  ),
                  DropdownMenuItem(
                    value: 'en',
                    child: Flag.fromCode(FlagsCode.GB, height: 20, width: 30),
                  ),
                  DropdownMenuItem(
                    value: 'tr',
                    child: Flag.fromCode(FlagsCode.TR, height: 20, width: 30),
                  ),
                  DropdownMenuItem(
                    value: 'pl',
                    child: Flag.fromCode(FlagsCode.PL, height: 20, width: 30),
                  ),
                  DropdownMenuItem(
                    value: 'es',
                    child: Flag.fromCode(FlagsCode.ES, height: 20, width: 30),
                  ),
                  DropdownMenuItem(
                    value: 'ar',
                    child: Flag.fromCode(FlagsCode.SY, height: 20, width: 30),
                  ),
                ],
              ),
            ),
          ],
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
                        Text(
                            AppLocalizations.of(context)!
                                .score(_score.toString()),
                            style: const TextStyle(fontSize: 18)),
                        const SizedBox(height: 20),
                        Text(
                            AppLocalizations.of(context)!
                                .timeLeft(_timeLeft.toString()),
                            style: const TextStyle(fontSize: 18)),
                        const SizedBox(height: 20),
                        GamePlayArea(
                          question: AppLocalizations.of(context)!
                              .problem((_currentProblem + 1).toString()),
                          task: _currentQuestion,
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
                        Text(AppLocalizations.of(context)!.selectDifficulty,
                            style: const TextStyle(fontSize: 18)),
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
                              child: Text(value == 'easy'
                                  ? AppLocalizations.of(context)!.easy
                                  : value == 'medium'
                                      ? AppLocalizations.of(context)!.medium
                                      : AppLocalizations.of(context)!.hard),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _startGame,
                          child: Text(AppLocalizations.of(context)!.startGame),
                        ),
                      ],
                    ),
            ),
          )
        ]));
  }
}