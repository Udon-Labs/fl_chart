import 'package:fl_chart/src/chart/line_chart/line_chart_renderer.dart';
import 'package:fl_chart/src/chart/line_chart/rope_chart_painter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// coverage:ignore-start

/// Low level RopeChart Widget.
class RopeChartLeaf extends LineChartLeaf {
  const RopeChartLeaf({
    super.key,
    required super.data,
    required super.targetData,
  });

  @override
  RenderRopeChart createRenderObject(BuildContext context) => RenderRopeChart(
        context,
        data,
        targetData,
        MediaQuery.of(context).textScaleFactor,
      );
}
// coverage:ignore-end

/// Renders our RopeChart, also handles hitTest.
class RenderRopeChart extends RenderLineChart {
  RenderRopeChart(
    super.context,
    super.data,
    super.targetData,
    super.textScale,
  ) {
    painter = RopeChartPainter();
  }
}
