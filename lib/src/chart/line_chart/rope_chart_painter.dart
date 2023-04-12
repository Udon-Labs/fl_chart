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
  void paint(
    BuildContext context,
    CanvasWrapper canvasWrapper,
    PaintHolder<LineChartData> holder,
  ) {
    super.paint(context, canvasWrapper, holder);

    final data = holder.data;
    for (var i = 0; i < data.lineBarsData.length; i++) {
      final barData = data.lineBarsData[i];
      if (!barData.show) {
        continue;
      }

      drawLastValueTracker(context, canvasWrapper, barData, holder);
    }
  }

  void drawLastValueTracker(
    BuildContext context,
    CanvasWrapper canvasWrapper,
    LineChartBarData barData,
    PaintHolder<LineChartData> holder,
  ) {
    if (barData.spots.isEmpty) {
      return;
    }

    final lastValue = barData.spots.last.y;
    final viewSize = canvasWrapper.size;
    final leftX = getPixelX(barData.mostLeftSpot.x, viewSize, holder);
    final yValue = getPixelY(lastValue, viewSize, holder);

    final leadingPainter = barData.lastValueTracker.leading?.call(lastValue);
    final textPainter = barData.lastValueTracker.text?.call(lastValue);

    final verticalPadding = barData.lastValueTracker.verticalPadding;
    final horizontalPadding = barData.lastValueTracker.horizontalPadding;
    final halfVerticalPadding = verticalPadding / 2;
    final halfHorizontalPadding = horizontalPadding / 2;

    var drawX = leftX;

    // callback to alert of the bar y value
    barData.lastValueTrackerUpdate?.call(yValue);

    if (leadingPainter != null) {
      leadingPainter.layout();

      final halfHeight = leadingPainter.height / 2;
      final halfWidth = leadingPainter.width / 2;
      final radius = halfHeight + halfVerticalPadding;

      canvasWrapper
        ..drawCircle(
          Offset(drawX + radius, yValue),
          radius,
          Paint()..color = barData.lastValueTracker.backgroundColor,
        )
        ..drawText(
          leadingPainter,
          Offset(drawX + radius - halfWidth, yValue - halfHeight),
        );

      drawX += 2 * radius;
    }

    if (textPainter != null) {
      textPainter.layout();

      final width = textPainter.width + horizontalPadding;
      final height = textPainter.height + verticalPadding;
      final top = yValue - height / 2;
      var left = drawX;

      if (leadingPainter != null) {
        left += 4;
      }

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, width, height),
        Radius.circular(height),
      );

      canvasWrapper
        ..drawRRect(
          rrect,
          Paint()..color = barData.lastValueTracker.backgroundColor,
        )
        ..drawText(
          textPainter,
          Offset(left + halfHorizontalPadding, top + halfVerticalPadding),
        );

      drawX = left + width;
    }

    // drawDashedLine(canvasWrapper, drawX, rightX, yValue);
  }

  void drawDashedLine(
    CanvasWrapper canvasWrapper,
    double leftX,
    double rightX,
    double yValue,
  ) {
    const dashWidth = 5.0;
    const strokeWidth = 3.0;
    const spaceWidth = 7.0;

    var startX = leftX;
    while (startX < rightX) {
      canvasWrapper.drawLine(
        Offset(startX, yValue),
        Offset(startX + dashWidth, yValue),
        Paint()
          ..color = Colors.grey
          ..strokeWidth = strokeWidth,
      );
      startX += dashWidth + spaceWidth;
    }
  }

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
