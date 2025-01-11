import 'dart:math';
import 'package:flutter/material.dart';

class SnowFlake {
  double x; // late final kaldırıldı
  double y;
  final double size;
  final double speed;
  double angle = 0; // Dönüş için yeni parametre

  SnowFlake({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
  });
}

class SnowPainter extends CustomPainter {
  final List<SnowFlake> snowflakes;

  SnowPainter(this.snowflakes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var snowflake in snowflakes) {
      // Kar kristali çizimi
      final center = Offset(snowflake.x, snowflake.y);
      final radius = snowflake.size;

      // Ana kollar (6 adet)
      for (int i = 0; i < 6; i++) {
        final angle = (i * 60) * (3.14159 / 180); // 60 derece aralıklarla
        canvas.drawLine(
          center,
          Offset(
            center.dx + cos(angle) * radius,
            center.dy + sin(angle) * radius,
          ),
          paint,
        );

        // Her ana kola küçük yan kollar ekle
        final sideLength = radius * 0.5;
        final midPoint = Offset(
          center.dx + cos(angle) * radius * 0.5,
          center.dy + sin(angle) * radius * 0.5,
        );

        // Yan kollar (her ana kolda 2 adet)
        final sideAngle1 = angle + (45 * (3.14159 / 180));
        final sideAngle2 = angle - (45 * (3.14159 / 180));

        canvas.drawLine(
          midPoint,
          Offset(
            midPoint.dx + cos(sideAngle1) * sideLength * 0.5,
            midPoint.dy + sin(sideAngle1) * sideLength * 0.5,
          ),
          paint,
        );

        canvas.drawLine(
          midPoint,
          Offset(
            midPoint.dx + cos(sideAngle2) * sideLength * 0.5,
            midPoint.dy + sin(sideAngle2) * sideLength * 0.5,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(SnowPainter oldDelegate) => true;
}
