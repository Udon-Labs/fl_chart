import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:fl_chart/src/chart/base/base_chart/base_chart_painter.dart';
import 'package:fl_chart/src/chart/line_chart/line_chart_painter.dart';
import 'package:fl_chart/src/chart/line_chart/rope_utils.dart';
import 'package:fl_chart/src/utils/canvas_wrapper.dart';
import 'package:flutter/material.dart';

/// Paints [LineChartData] in the canvas, it can be used in a [CustomPainter]
class RopeChartPainter extends LineChartPainter {
  RopeChartPainter() : super();

  @override
  void drawBarLine(
    CanvasWrapper canvasWrapper,
    LineChartBarData barData,
    PaintHolder<LineChartData> holder,
  ) {
    const width = 15.0;
    const angle = pi * 0.75;

    final viewSize = canvasWrapper.size;

    if (barData.spots.isEmpty) {
      return;
    }

    final path = generateBarPath(viewSize, barData, barData.spots, holder);
    final points = getPathPoints(path: path);
    final normals = getLines(points, width, angleOffset: angle);
    final segments = getSegments(normals, fixGaps: true);

    for (var i = 0; i < segments.length; i++) {
      final offsets = segments[i].points.map((s) => Offset(s.x, s.y)).toList();
      final path = Path()..addPolygon(offsets, true);

      var color = barData.color ?? Colors.transparent;
      final ropeColors = barData.ropeStyle.colors;
      if (ropeColors != null) {
        color = ropeColors[i % ropeColors.length];
      }

      // paint fill
      final paint = Paint()..color = color;
      canvasWrapper.drawPath(path, paint);

      // paint outline
      paint
        ..style = PaintingStyle.stroke
        ..color = Colors.black12
        ..strokeWidth = 0.75;
      canvasWrapper.drawPath(path, paint);
    }
  }
}
