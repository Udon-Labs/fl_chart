import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

typedef Line = List<FlSpot>;

class ChartSegment {
  ChartSegment({
    required this.line1,
    required this.line2,
    required this.path,
    required this.points,
  });

  final Line line1;
  final Line line2;
  final List<FlSpot> path;
  final List<FlSpot> points;
}

double getAngle(FlSpot pointA, FlSpot pointB) {
  final num lengthX = pointB.x - pointA.x;
  final num lengthY = pointB.y - pointA.y;
  return atan2(lengthY, lengthX);
}

double getDistanceBetweenPoints(FlSpot v1, FlSpot v2) {
  final x = v1.x - v2.x;
  final y = v1.y - v2.y;
  return sqrt(x * x + y * y);
}

FlSpot getVector(FlSpot a, FlSpot b) {
  return FlSpot(
    b.x - a.x,
    b.y - a.y,
  );
}

FlSpot multiplyVector(FlSpot chartPoint, double scalar) {
  return FlSpot(
    chartPoint.x * scalar,
    chartPoint.y * scalar,
  );
}

double getVectorVelocity(FlSpot v) {
  final x = -v.x;
  final y = -v.y;
  return sqrt(x * x + y * y);
}

// Position of a control point
FlSpot controlPoint({
  required FlSpot previous,
  required FlSpot current,
  required FlSpot next,
  required double length,
  required bool reverse,
}) {
  final angle = getAngle(previous, current) + (reverse ? pi : 0);
  final x = current.x + cos(angle) * length;
  final y = current.y + sin(angle) * length;
  return FlSpot(x, y);
}

double getPercentageOfNumberBetweenTwoNumbers({
  required int start,
  required int end,
  required int value,
}) {
  final difference = (end - start).abs();
  final differenceFromStart = value - start;
  final percentage = differenceFromStart / difference;
  return percentage;
}

double getPathLength(Path path) {
  var length = 0.0;
  final metrics = path.computeMetrics();

  for (final metric in metrics) {
    length += metric.length;
  }
  return length;
}

Offset getPointAtLength(Path path, double length) {
  var currentLength = 0.0;
  final metrics = path.computeMetrics();
  for (final metric in metrics) {
    if (currentLength + metric.length >= length) {
      return metric.getTangentForOffset(length - currentLength)!.position;
    }
    currentLength += metric.length;
  }
  return Offset.zero;
}

List<FlSpot> getPathPoints({required Path path, double step = 10}) {
  final points = <FlSpot>[];

  final length = getPathLength(path);

  final count = length / step;

  for (var i = 0; i < count + 1; i++) {
    final n = i * step;
    final point = getPointAtLength(path, n);

    points.add(FlSpot(point.dx, point.dy));
  }

  return points;
}

List<FlSpot> cut({
  required FlSpot start,
  required FlSpot end,
  required double ratio,
}) {
  final r1 = FlSpot(
    start.x * (1 - ratio) + end.x * ratio,
    start.y * (1 - ratio) + end.y * ratio,
  );
  final r2 = FlSpot(
    start.x * ratio + end.x * (1 - ratio),
    start.y * ratio + end.y * (1 - ratio),
  );
  return [r1, r2];
}

List<FlSpot> chaikin({
  required List<FlSpot> curve,
  int iterations = 1,
  bool closed = false,
  double ratio = 0.25,
}) {
  if (ratio > 0.5) {
    // ignore: parameter_assignments
    ratio = 1 - ratio;
  }

  for (var i = 0; i < iterations; i++) {
    var refined = <FlSpot>[curve[0]];

    for (var j = 1; j < curve.length; j++) {
      final points = cut(start: curve[j - 1], end: curve[j], ratio: ratio);
      refined = refined + points;
    }

    if (closed) {
      refined.removeAt(0);
      refined = refined + cut(start: curve[curve.length - 1], end: curve[0], ratio: ratio);
    } else {
      refined.add(curve[curve.length - 1]);
    }

    // ignore: parameter_assignments
    curve = refined;
  }
  return curve;
}

FlSpot addVectors(FlSpot a, FlSpot b) {
  return FlSpot(
    a.x + b.x,
    a.y + b.y,
  );
}

double getAngle3(FlSpot a, FlSpot b, FlSpot c) {
  final vectorBA = getVector(a, b);
  final vectorBC = getVector(c, b);

  final angle = atan2(vectorBC.y, vectorBC.x) - atan2(vectorBA.y, vectorBA.x);

  return angle;
}

// Takes three dots and returns two dots,
// a vector which direction is half angle between these three dots
// and velocity is equal to a spiral line's width at that dot
/*
                          • outerDots[0]
                         /
                        /
             v1 •------• v2
                      / \
                     /   • v3
       outerDots[1] •
  */
List<FlSpot> getOuterPoints({
  required FlSpot v1,
  required FlSpot v2,
  required FlSpot v3,
  required double width,
  double angleOffset = 0,
}) {
  // Angle between (v1, v2) vector and x axis
  /*
             v1 •------• v2
                angle1 / \
                      /   • v3
  */
  final angle1 = getAngle3(v1, v2, v3) / 2;

  var offset = 100;

  if (angle1 > 0) {
    offset = -100;
  }
  // Angle between (v1, v2) vector and x axis
  /*
                 v2 •--------• (v2.x + offset, v2.y)
                   / angle2
                  /
             v1 •
  */
  final angle2 = getAngle3(
    v1,
    v2,
    FlSpot(
      v2.x + offset, // Moving dot on x axis
      v2.y,
    ),
  );

  // Angle between the x axis and the half angle vector
  final angle = angle2 - angle1 + angleOffset;

  final halfWidth = width / 2;

  final point1 = FlSpot(
    v2.x + halfWidth * cos(angle),
    v2.y - halfWidth * sin(angle),
  );

  final point2 = FlSpot(
    v2.x + halfWidth * cos(angle + pi),
    v2.y - halfWidth * sin(angle + pi),
  );

  return [point1, point2];
}

FlSpot getPointOnLine(FlSpot start, FlSpot end, double ratio) {
  final vector = getVector(start, end);
  final v = multiplyVector(vector, ratio);
  return FlSpot(
    start.x + v.x,
    start.y + v.y,
  );
}

List<Line> getLines(
  List<FlSpot> points,
  double thickness, {
  double angleOffset = 0,
}) {
  final normals = <Line>[];

  for (var i = 1; i < points.length - 1; i++) {
    final v1 = points[i - 1];
    final v2 = points[i];
    final v3 = points[i + 1];

    final line = getOuterPoints(
      v1: v1,
      v2: v2,
      v3: v3,
      width: thickness,
      angleOffset: angleOffset,
    );

    normals.add(line);
  }

  if (normals.isNotEmpty) {
    normals.add(normals.last);
  }

  return normals;
}

List<ChartSegment> getSegments(
  List<Line> normals, {
  bool fixGaps = false,
  double ratio = 0.3,
}) {
  final segments = <ChartSegment>[];

  for (var i = 0; i < normals.length - 2; i++) {
    final l1 = normals[i];
    final l2 = normals[i + 1];
    final l3 = normals[i + 2];
    final path = [l1[0], l1[1], l2[1], l2[0]];

    final prevSegment = i > 0 ? segments.elementAt(i - 1) : null;

    final A = l1[0];
    final B = l1[1];
    final C = l2[0];
    final D = l2[1];
    final E = l3[0];

    final ratio2 = 1 - ratio;

    final bd033 = getPointOnLine(B, D, 0.33);
    final dcP1 = getPointOnLine(D, C, ratio);
    var corner1 = getPointOnLine(bd033, dcP1, 0.5);
    // Move the point closer to the corner
    corner1 = addVectors(corner1, multiplyVector(getVector(corner1, D), 0.25));
    final dcP2 = getPointOnLine(D, C, ratio2);
    final ce066 = getPointOnLine(C, E, 0.66);
    var corner2 = getPointOnLine(dcP2, ce066, 0.5);
    // Move the point closer to the corner
    corner2 = addVectors(corner2, multiplyVector(getVector(corner2, C), 0.25));
    final ac066 = getPointOnLine(A, C, 0.66);
    final abP1 = getPointOnLine(A, B, ratio);
    final abP2 = getPointOnLine(A, B, ratio2);

    final line1 = [
      if (prevSegment != null) prevSegment.line1[2] else B,
      bd033,
      corner1,
      if (fixGaps) corner1,
      if (fixGaps) corner1,
      dcP1,
      dcP2,
      corner2
    ];

    final line2 = [
      corner2,
      ac066,
      if (prevSegment != null) prevSegment.line1[fixGaps ? 7 : 5],
      if (prevSegment != null && fixGaps) prevSegment.line1[7],
      if (prevSegment != null && fixGaps) prevSegment.line1[7],
      abP1,
      if (prevSegment != null) abP2,
      if (prevSegment != null) prevSegment.line1[2] else B
    ];

    final roundedLine1 = chaikin(curve: line1, iterations: 2);
    final roundedLine2 = chaikin(curve: line2, iterations: 2);
    roundedLine1.removeLast();
    roundedLine2.removeLast();
    final points = [...roundedLine1, ...roundedLine2];

    segments.add(
      ChartSegment(
        line1: line1,
        line2: line1,
        path: path,
        points: points,
      ),
    );
  }

  return segments;
}
