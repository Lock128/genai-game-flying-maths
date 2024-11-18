import 'dart:async';

import 'package:flutter/material.dart';

class AnimatedAnswerBox extends StatefulWidget {
  final String answer;
  final bool isCorrect;
  final VoidCallback onTap;
  final int index;  // Added index for staggered animation

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

class _AnimatedAnswerBoxState extends State<AnimatedAnswerBox> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _hasStarted = false;
  bool _isStopped = false;
  Timer? _restartTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 15000),
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: -0.2,  // Start slightly left of screen
      end: 1.2,    // End slightly right of screen
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,  // Use linear for constant speed
    ));

    // Listen for animation completion to restart
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_isStopped) {
        // Instead of immediately resetting, start from right side and animate after a short delay
        _restartTimer?.cancel();
        _restartTimer = Timer(const Duration(milliseconds: 100), () {
          if (mounted && !_isStopped) {
            _controller.reset();
            _controller.forward();
          }
        });
      }
    });

    // Only start animation after a delay based on index
    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      setState(() {
        _hasStarted = true;
      });
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.stop();
    _controller.dispose();
    _restartTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(AnimatedAnswerBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.answer != widget.answer) {
      setState(() {
        _isStopped = false;
        _hasStarted = false;
      });
      _controller.reset();
      Future.delayed(Duration(milliseconds: widget.index * 100), () {
        if (mounted) {
          setState(() {
            _hasStarted = true;
          });
          _controller.forward();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // Calculate position based on screen width
        final width = MediaQuery.of(context).size.width;
        final position = _animation.value * width;

        return Positioned(
          left: position - 100,
          top: 150 + (widget.index * 80), // Increased vertical spacing between answers
          child: Opacity(
            opacity: _hasStarted ? 1.0 : 0.0,
            child:GestureDetector(
            onTap: () {
                if (_hasStarted) {
                  setState(() {
                    _isStopped = true;
                  });
                  _controller.stop();
                  widget.onTap();
                }
              },
            child: Container(
              width: 200,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: Text(
                widget.answer,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ));
      },
    );
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
    return SizedBox(
      width: double.infinity,
      height: 600, // Increased height for better spacing
      child: Stack(
        children: [
          // Question display at the top
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                widget.question,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Answer boxes
          ...List.generate(
            widget.possibleAnswers.length,
            (index) {
              final answer = widget.possibleAnswers[index];
              final isCorrect = answer == widget.correctAnswer;
              
              return AnimatedAnswerBox(
                answer: answer,
                isCorrect: isCorrect,
                onTap: () => widget.onAnswerSubmitted(isCorrect, answer),
                index: index,
              );
            },
          ),
        ],
      ),
    );
  }
}