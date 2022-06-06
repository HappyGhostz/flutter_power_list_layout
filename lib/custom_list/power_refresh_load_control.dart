import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

typedef SliverPowerWidgetBuilder = Widget Function(
  BuildContext context,
  double maxExtent,
  //ScrollDirection direction,
);

class PowerRefreshOrLoadControlWidget extends StatefulWidget {
  const PowerRefreshOrLoadControlWidget({Key? key, required this.builder, this.visibleExtent = 60}) : super(key: key);

  final SliverPowerWidgetBuilder builder;
  final double visibleExtent;

  @override
  State<StatefulWidget> createState() => _PowerRefreshOrLoadControlWidgetState();
}

class _PowerRefreshOrLoadControlWidgetState extends State<PowerRefreshOrLoadControlWidget> {
  @override
  Widget build(BuildContext context) {
    return PowerRefreshOrLoadSliverWidget(
      visibleExtent: widget.visibleExtent,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return widget.builder(context, constraints.maxHeight);
        },
      ),
    );
  }
}

class PowerRefreshOrLoadSliverWidget extends SingleChildRenderObjectWidget {
  const PowerRefreshOrLoadSliverWidget({
    Key? key,
    required Widget child,
    this.visibleExtent = 60,
  }) : super(key: key, child: child);

  final double visibleExtent;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return PowerRefreshOrLoadRenderSliver(visibleExtent: visibleExtent);
  }

  @override
  void updateRenderObject(BuildContext context, covariant PowerRefreshOrLoadRenderSliver renderObject) {
    renderObject.visibleExtent = visibleExtent;
  }
}

class PowerRefreshOrLoadRenderSliver extends RenderSliverSingleBoxAdapter {
  PowerRefreshOrLoadRenderSliver({
    required double visibleExtent,
  }) : _visibleExtent = visibleExtent;

  double _lastOverScroll = 0;
  double _lastScrollOffset = 0;
  double _visibleExtent = 0;

  set visibleExtent(double value) {
    if (_visibleExtent != value) {
      _lastOverScroll = 0;
      _visibleExtent = value;
      // markNeedsLayout();
    }
  }

  @override
  void performLayout() {
    if (child == null) {
      geometry = SliverGeometry.zero;
      return;
    }
    final SliverConstraints constraints = this.constraints;

    final bool active = constraints.overlap < 0.0;
    final double overScrolledExtent = constraints.overlap < 0.0 ? constraints.overlap.abs() : 0.0;

    print('overlap:${constraints.overlap}');

    final double childExtent = _visibleExtent;

    child!.layout(constraints.asBoxConstraints(maxExtent: childExtent + overScrolledExtent), parentUsesSize: true);
    print('maxExtent:${childExtent + overScrolledExtent}');

    final double paintedChildSize = max(
      max(child!.size.height, childExtent),
      0.0,
    );
    final double paintChildOrigin = min(overScrolledExtent - childExtent, 0);
    final double maxPaintExtent = max(
      max(child!.size.height, childExtent),
      0.0,
    );
    if (active) {
      geometry = SliverGeometry(
        scrollExtent: childExtent,
        paintExtent: paintedChildSize,
        paintOrigin: paintChildOrigin,
        maxPaintExtent: maxPaintExtent,
        layoutExtent: min(overScrolledExtent, childExtent),
      );
    } else {
      geometry = SliverGeometry.zero;
    }
  }
}
