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

    // Cabin
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.4, size.height * 0.55),
        width: size.width * 0.4,
        height: size.height * 0.35,
      ),
      paint,
    );

    // Tail boom
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.6, size.height * 0.5)
        ..lineTo(size.width * 0.9, size.height * 0.5)
        ..lineTo(size.width * 0.9, size.height * 0.6)
        ..lineTo(size.width * 0.6, size.height * 0.6)
        ..close(),
      paint,
    );

    // Tail rotor
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.9, size.height * 0.4)
        ..lineTo(size.width * 0.95, size.height * 0.4)
        ..lineTo(size.width * 0.95, size.height * 0.7)
        ..lineTo(size.width * 0.9, size.height * 0.7)
        ..close(),
      paint,
    );

    // Main rotor blades
    canvas.save();
    canvas.translate(size.width * 0.4, size.height * 0.4);
    for (var i = 0; i < 4; i++) {
      canvas.drawLine(
        Offset(-size.width * 0.3, 0),
        Offset(size.width * 0.3, 0),
        paint..strokeWidth = 3,
      );
      canvas.rotate(pi / 2);
    }
    canvas.restore();
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

    // Fuselage
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.15, size.height * 0.5)
        ..quadraticBezierTo(
          size.width * 0.4, size.height * 0.45,
          size.width * 0.85, size.height * 0.5,
        )
        ..lineTo(size.width * 0.85, size.height * 0.65)
        ..quadraticBezierTo(
          size.width * 0.4, size.height * 0.7,
          size.width * 0.15, size.height * 0.65,
        )
        ..close(),
      paint,
    );

    // Wings
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.3, size.height * 0.55)
        ..lineTo(size.width * 0.15, size.height * 0.3)
        ..lineTo(size.width * 0.45, size.height * 0.3)
        ..lineTo(size.width * 0.6, size.height * 0.55)
        ..close(),
      paint,
    );

    // Tail wings
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.75, size.height * 0.35)
        ..lineTo(size.width * 0.85, size.height * 0.25)
        ..lineTo(size.width * 0.95, size.height * 0.35)
        ..lineTo(size.width * 0.85, size.height * 0.45)
        ..close(),
      paint,
    );
    
    // Nose
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.15, size.height * 0.575),
        width: size.width * 0.1,
        height: size.height * 0.15,
      ),
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
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.3, size.height * 0.6)
        ..quadraticBezierTo(
          size.width * 0.5, size.height * 0.5,
          size.width * 0.7, size.height * 0.6,
        )
        ..lineTo(size.width * 0.7, size.height * 0.7)
        ..quadraticBezierTo(
          size.width * 0.5, size.height * 0.8,
          size.width * 0.3, size.height * 0.7,
        )
        ..close(),
      paint,
    );

    // Wings
    for (final offset in [0.4, 0.6]) {
      canvas.save();
      canvas.translate(size.width * offset, size.height * 0.6);
      canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(
            size.width * 0.1, size.height * -0.3,
            size.width * 0.2, 0,
          ),
        paint..style = PaintingStyle.stroke..strokeWidth = 3,
      );
      canvas.restore();
    }

    // Head and beak
    canvas.drawCircle(
      Offset(size.width * 0.75, size.height * 0.55),
      size.width * 0.08,
      paint..style = PaintingStyle.fill,
    );
    
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.8, size.height * 0.52)
        ..lineTo(size.width * 0.9, size.height * 0.55)
        ..lineTo(size.width * 0.8, size.height * 0.58)
        ..close(),
      paint,
    );

    // Tail feathers
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.3, size.height * 0.6)
        ..quadraticBezierTo(
          size.width * 0.2, size.height * 0.65,
          size.width * 0.15, size.height * 0.7,
        )
        ..quadraticBezierTo(
          size.width * 0.25, size.height * 0.65,
          size.width * 0.3, size.height * 0.7,
        ),
      paint..style = PaintingStyle.stroke..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}