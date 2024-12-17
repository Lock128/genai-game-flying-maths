import 'dart:math';
import 'package:flutter/material.dart';

enum VehicleType {
  helicopter,
  airplane,
  bird
}

class VehicleGraphics {
  static final Random _random = Random();
  
  static VehicleType getRandomVehicle() {
    return VehicleType.values[_random.nextInt(VehicleType.values.length)];
  }

  static CustomPaint buildVehicleGraphic(VehicleType type, Size size, Color color) {
    return CustomPaint(
      size: size,
      painter: switch (type) {
        VehicleType.helicopter => HelicopterPainter(color),
        VehicleType.airplane => AirplanePainter(color),
        VehicleType.bird => BirdPainter(color),
      },
    );
  }
}

class HelicopterPainter extends CustomPainter {
  final Color color;
  HelicopterPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Body
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.3, size.height * 0.5)
        ..lineTo(size.width * 0.8, size.height * 0.5)
        ..lineTo(size.width * 0.9, size.height * 0.7)
        ..lineTo(size.width * 0.2, size.height * 0.7)
        ..close(),
      paint,
    );

    // Tail
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.8, size.height * 0.55)
        ..lineTo(size.width * 0.95, size.height * 0.4)
        ..lineTo(size.width * 0.9, size.height * 0.35)
        ..lineTo(size.width * 0.75, size.height * 0.5)
        ..close(),
      paint,
    );

    // Main rotor
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.3),
      Offset(size.width * 0.9, size.height * 0.3),
      paint..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class AirplanePainter extends CustomPainter {
  final Color color;
  AirplanePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Body
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.1, size.height * 0.5)
        ..lineTo(size.width * 0.9, size.height * 0.5)
        ..lineTo(size.width * 0.8, size.height * 0.7)
        ..lineTo(size.width * 0.2, size.height * 0.7)
        ..close(),
      paint,
    );

    // Wings
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.3, size.height * 0.5)
        ..lineTo(size.width * 0.5, size.height * 0.2)
        ..lineTo(size.width * 0.7, size.height * 0.5)
        ..close(),
      paint,
    );

    // Tail wing
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.7, size.height * 0.5)
        ..lineTo(size.width * 0.8, size.height * 0.3)
        ..lineTo(size.width * 0.9, size.height * 0.5)
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class BirdPainter extends CustomPainter {
  final Color color;
  BirdPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Body
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.6),
        width: size.width * 0.6,
        height: size.height * 0.3,
      ),
      paint,
    );

    // Wings
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.3, size.height * 0.6)
        ..quadraticBezierTo(
          size.width * 0.5, size.height * 0.2,
          size.width * 0.7, size.height * 0.6,
        ),
      paint..style = PaintingStyle.stroke..strokeWidth = 3,
    );

    // Head
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.55),
      size.width * 0.1,
      paint..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}