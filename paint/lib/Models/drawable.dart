import 'package:flutter/material.dart';

abstract class Drawable {
  void draw(Canvas canvas);
}

class Line extends Drawable {
  final Offset start;
  final Offset end;
  final Color color;
  final double strokeWidth;

  Line({
    required this.start,
    required this.end,
    this.color = Colors.black,
    this.strokeWidth = 2.0,
  });

  @override
  void draw(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth;
    canvas.drawLine(start, end, paint);
  }
}

class Rectangle extends Drawable {
  final Offset topLeft;
  final Offset bottomRight;
  final Color borderColor;
  final Color fillColor;
  final double borderWidth;
  final Gradient? gradient;

  Rectangle({
    required this.topLeft,
    required this.bottomRight,
    this.borderColor = Colors.black,
    this.fillColor = Colors.transparent,
    this.borderWidth = 2.0,
    this.gradient,
  });

  @override
  void draw(Canvas canvas) {
    final rect = Rect.fromPoints(topLeft, bottomRight);

    if (gradient != null) {
      final gradientPaint = Paint()
        ..shader = gradient!.createShader(rect)
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, gradientPaint);
    } else if (fillColor != Colors.transparent) {
      final fillPaint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, fillPaint);
    }

    if (borderWidth > 0) {
      final strokePaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth;
      canvas.drawRect(rect, strokePaint);
    }
  }
}

class Circle extends Drawable {
  final Offset center;
  final double radius;
  final Color borderColor;
  final Color fillColor;
  final double borderWidth;
  final Gradient? gradient;

  Circle({
    required this.center,
    required this.radius,
    this.borderColor = Colors.black,
    this.fillColor = Colors.transparent,
    this.borderWidth = 2.0,
    this.gradient,
  });

  @override
  void draw(Canvas canvas) {
    if (gradient != null) {
      final gradientPaint = Paint()
        ..shader = gradient!.createShader(
          Rect.fromCircle(center: center, radius: radius),
        )
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, gradientPaint);
    } else if (fillColor != Colors.transparent) {
      final fillPaint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, fillPaint);
    }

    if (borderWidth > 0) {
      final strokePaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth;
      canvas.drawCircle(center, radius, strokePaint);
    }
  }
}

class TextElement extends Drawable {
  final String text;
  final Offset position;
  final Color color;
  final double fontSize;
  final String fontFamily;
  final FontStyle fontStyle;
  final FontWeight fontWeight;

  TextElement({
    required this.text,
    required this.position,
    this.color = Colors.black,
    this.fontSize = 14.0,
    this.fontFamily = 'Roboto',
    this.fontStyle = FontStyle.normal,
    this.fontWeight = FontWeight.normal,
  });

  @override
  void draw(Canvas canvas) {
    final textStyle = TextStyle(
      color: color,
      fontSize: fontSize,
      fontFamily: fontFamily,
      fontStyle: fontStyle,
      fontWeight: fontWeight,
    );
    final textSpan = TextSpan(
      text: text,
      style: textStyle,
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }
}
