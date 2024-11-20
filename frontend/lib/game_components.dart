import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AnimatedAnswerBox extends StatefulWidget {
  final String answer;
  final bool isCorrect;
  final VoidCallback onTap;
  final int index;

  const AnimatedAnswerBox({
    Key? key,
    required this.answer,
    required this.isCorrect,
    required this.onTap,
    required this.index,
  }) : super(key: key);

  @override
  _AnimatedAnswerBoxState createState() => _AnimatedAnswerBoxState();
}

class _AnimatedAnswerBoxState extends State<AnimatedAnswerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isVisible = false;
  bool _isStopped = false;

  @override
  void initState() {
    super.initState();

    // Initialize the animation controller
    _controller = AnimationController(
      duration:
          const Duration(milliseconds: 25000), // 8 seconds to cross screen
      vsync: this,
    );

    // Create the animation
    _animation = Tween<double>(
      begin: -0.01, // Start from left of screen
      end: 1.1, // End right of screen
    ).animate(_controller);

    // Start the animation after a delay based on index
    Future.delayed(Duration(milliseconds: widget.index * 200), () {
      if (mounted) {
        setState(() {
          _isVisible = true;
        });
        _controller.repeat(); // Makes the animation loop continuously
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        //print("widget.index: ${widget.index} -> ${widget.answer} | animation.value: ${_animation.value} | widget.left: ${screenWidth * _animation.value} | widget.top: ${50.0 + (widget.index * 20.0)}");

        return Positioned(
          // Calculate position based on screen width
          left: (screenWidth * _animation.value),
          top: 50.0 + (widget.index * 70.0), // Vertical spacing between items
          child: Opacity(
            opacity: _isVisible ? 1.0 : 0.0,
            child: GestureDetector(
              onTap: () {
                if (!_isStopped) {
                  setState(() {
                    _isStopped = true;
                  });
                  _controller.stop();
                  widget.onTap();
                }
              },
              child: Container(
                width: 180,
                height: 55,
                decoration: BoxDecoration(
                  color: Colors.blue.shade500,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.answer,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AnimatedAnswerBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.answer != oldWidget.answer) {
      // Reset animation when answer changes
      setState(() {
        _isStopped = false;
        _isVisible = false;
      });
      _controller.reset();

      Future.delayed(Duration(milliseconds: widget.index * 1000), () {
        if (mounted) {
          setState(() {
            _isVisible = true;
          });
          _controller.repeat();
        }
      });
    }
  }
}

class GamePlayArea extends StatefulWidget {
  final String question;
  final List<String> possibleAnswers;
  final String correctAnswer;
  final Function(bool, String) onAnswerSubmitted;

  const GamePlayArea({
    Key? key,
    required this.question,
    required this.possibleAnswers,
    required this.correctAnswer,
    required this.onAnswerSubmitted,
  }) : super(key: key);

  @override
  _GamePlayAreaState createState() => _GamePlayAreaState();
}

class _GamePlayAreaState extends State<GamePlayArea> {
  @override
  Widget build(BuildContext context) {
    //print question
    print(
        "build _GamePlayAreaState - question: ${widget.question} | answer: ${widget.correctAnswer} | possible: ${widget.possibleAnswers}");

    if (!widget.possibleAnswers.contains(widget.correctAnswer)) {
      throw Exception("Correct answer not in possible answers");
    }

    return Expanded(child: LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Container(
                width: double.infinity,
                height: 600,
                child: Stack(
                  children: [
                    Positioned(
                      top: 20,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          widget.question,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    ...widget.possibleAnswers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final answer = entry.value;
                      final isCorrect = answer == widget.correctAnswer;
                      // print index, answer and isCorrect
                      //print("index: $index, answer: $answer, isCorrect: $isCorrect");
                      //print("\tValueKey: answer_$index${widget.question}");
                      return AnimatedAnswerBox(
                        key: ValueKey('answer_$index${widget.question}'),
                        answer: answer,
                        isCorrect: isCorrect,
                        onTap: () =>
                            widget.onAnswerSubmitted(isCorrect, answer),
                        index: index,
                      );
                    }).toList(),
                  ],
                ),
              )));
    }));
  }

  @override
  void didUpdateWidget(GamePlayArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question != widget.question ||
        !listEquals(oldWidget.possibleAnswers, widget.possibleAnswers) ||
        oldWidget.correctAnswer != widget.correctAnswer) {
      // Only perform updates if the data actually changed
      setState(() {
        // Update any state if needed
      });
    }
  }
}
