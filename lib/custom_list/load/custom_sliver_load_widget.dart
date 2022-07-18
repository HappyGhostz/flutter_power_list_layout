import 'dart:math';

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

class PowerLoadSliverWidget extends SingleChildRenderObjectWidget {
  const PowerLoadSliverWidget({
    Key? key,
    this.loadIndicatorLayoutExtent = 0.0,
    this.hasLayoutExtent = false,
    this.enableInfiniteLoad = false,
    this.footerFloat = false,
    required this.axisDirectionNotifier,
    required this.infiniteLoad,
    required this.extraExtentNotifier,
    required Widget child,
  })  : assert(loadIndicatorLayoutExtent >= 0.0),
        super(key: key, child: child);

  // The amount of space the indicator should occupy in the sliver in a
  // resting state when in the refreshing mode.
  final double loadIndicatorLayoutExtent;

  // _RenderEasyRefreshSliverLoad will paint the child in the available
  // space either way but this instructs the _RenderEasyRefreshSliverLoad
  // on whether to also occupy any layoutExtent space or not.
  final bool hasLayoutExtent;

  /// Whether to enable infinite load
  final bool enableInfiniteLoad;

  /// infinite loading callback
  final VoidCallback infiniteLoad;

  /// Footer float
  final bool footerFloat;

  /// list direction
  final ValueNotifier<AxisDirection> axisDirectionNotifier;

  // Extra length when the list is full
  final ValueNotifier<double> extraExtentNotifier;

  @override
  PowerLoadRenderSliver createRenderObject(BuildContext context) {
    return PowerLoadRenderSliver(
      loadIndicatorExtent: loadIndicatorLayoutExtent,
      hasLayoutExtent: hasLayoutExtent,
      enableInfiniteLoad: enableInfiniteLoad,
      infiniteLoad: infiniteLoad,
      extraExtentNotifier: extraExtentNotifier,
      footerFloat: footerFloat,
      axisDirectionNotifier: axisDirectionNotifier,
    );
  }

  @override
  void updateRenderObject(BuildContext context, covariant PowerLoadRenderSliver renderObject) {
    renderObject
      ..loadIndicatorLayoutExtent = loadIndicatorLayoutExtent
      ..hasLayoutExtent = hasLayoutExtent
      ..enableInfiniteLoad = enableInfiniteLoad
      ..footerFloat = footerFloat;
  }
}

// RenderSliver object that gives its child RenderBox object space to paint
// in the overscrolled gap and may or may not hold that overscrolled gap
// around the RenderBox depending on whether [layoutExtent] is set.
//
// The [layoutExtentOffsetCompensation] field keeps internal accounting to
// prevent scroll position jumps as the [layoutExtent] is set and unset.
class PowerLoadRenderSliver extends RenderSliverSingleBoxAdapter {
  PowerLoadRenderSliver({
    required double loadIndicatorExtent,
    required bool hasLayoutExtent,
    required bool enableInfiniteLoad,
    required this.infiniteLoad,
    required this.extraExtentNotifier,
    required this.axisDirectionNotifier,
    required bool footerFloat,
    RenderBox? child,
  })  : assert(loadIndicatorExtent >= 0.0),
        _loadIndicatorExtent = loadIndicatorExtent,
        _enableInfiniteLoad = enableInfiniteLoad,
        _hasLayoutExtent = hasLayoutExtent,
        _footerFloat = footerFloat {
    this.child = child;
  }

  /// list direction
  final ValueNotifier<AxisDirection> axisDirectionNotifier;

  // The amount of layout space the indicator should occupy in the sliver in a
  // resting state when in the refreshing mode.
  double get loadIndicatorLayoutExtent => _loadIndicatorExtent;
  double _loadIndicatorExtent;

  set loadIndicatorLayoutExtent(double value) {
    assert(value >= 0.0);
    if (value == _loadIndicatorExtent) return;
    _loadIndicatorExtent = value;
    markNeedsLayout();
  }

  // The child box will be laid out and painted in the available space either
  // way but this determines whether to also occupy any
  // [SliverGeometry.layoutExtent] space or not.
  bool get hasLayoutExtent => _hasLayoutExtent;
  bool _hasLayoutExtent;

  set hasLayoutExtent(bool value) {
    if (value == _hasLayoutExtent) return;
    _hasLayoutExtent = value;
    markNeedsLayout();
  }

  /// Whether to enable infinite loading
  bool get enableInfiniteLoad => _enableInfiniteLoad;
  bool _enableInfiniteLoad;

  set enableInfiniteLoad(bool value) {
    if (value == _enableInfiniteLoad) return;
    _enableInfiniteLoad = value;
    markNeedsLayout();
  }

  /// Whether the Header is floating
  bool get footerFloat => _footerFloat;
  bool _footerFloat;

  set footerFloat(bool value) {
    if (value == _footerFloat) return;
    _footerFloat = value;
    markNeedsLayout();
  }

  /// infinite loading callback
  final VoidCallback infiniteLoad;

  // Extra length when the list is full
  final ValueNotifier<double> extraExtentNotifier;

  // Trigger infinite loading
  bool _triggerInfiniteLoad = false;

  // Get child component size
  double get childSize => constraints.axis == Axis.vertical ? child!.size.height : child!.size.width;

  // This keeps track of the previously applied scroll offsets to the scrollable
  // so that when [loadIndicatorLayoutExtent] or [hasLayoutExtent] changes,
  // the appropriate delta can be applied to keep everything in the same place
  // visually.
  double layoutExtentOffsetCompensation = 0.0;

  @override
  void performLayout() {
    // Determine whether the list is not full, remove the height that is not full
    double extraExtent = 0.0;
    if (constraints.precedingScrollExtent < constraints.viewportMainAxisExtent) {
      extraExtent = constraints.viewportMainAxisExtent - constraints.precedingScrollExtent;
    }
    extraExtentNotifier.value = extraExtent;

    // Only pulling to refresh from the top is currently supported.
    // assert(constraints.axisDirection == AxisDirection.down);
    assert(constraints.growthDirection == GrowthDirection.forward);

    // Determine whether to trigger infinite loading
    if ((enableInfiniteLoad && extraExtentNotifier.value < constraints.remainingPaintExtent ||
            (extraExtentNotifier.value == constraints.remainingPaintExtent && constraints.cacheOrigin < 0.0)) &&
        constraints.remainingPaintExtent > 1.0) {
      if (!_triggerInfiniteLoad) {
        _triggerInfiniteLoad = true;
        infiniteLoad();
      }
    } else {
      if (constraints.remainingPaintExtent <= 1.0 ||
          extraExtent > 0.0 ||
          (enableInfiniteLoad && extraExtentNotifier.value == constraints.remainingPaintExtent)) {
        if (SchedulerBinding.instance!.schedulerPhase == SchedulerPhase.idle) {
          _triggerInfiniteLoad = false;
        } else {
          SchedulerBinding.instance!.addPostFrameCallback((Duration timestamp) {
            _triggerInfiniteLoad = false;
          });
        }
      }
    }

    // The new layout extent this sliver should now have.
    final double layoutExtent = (_hasLayoutExtent || enableInfiniteLoad ? 1.0 : 0.0) * _loadIndicatorExtent;
    // If the new layoutExtent instructive changed, the SliverGeometry's
    // layoutExtent will take that value (on the next performLayout run). Shift
    // the scroll offset first so it doesn't make the scroll position suddenly jump.
    /*if (layoutExtent != layoutExtentOffsetCompensation) {
      geometry = SliverGeometry(
        scrollOffsetCorrection: layoutExtent - layoutExtentOffsetCompensation,
      );
      layoutExtentOffsetCompensation = layoutExtent;
      // Return so we don't have to do temporary accounting and adjusting the
      // child's constraints accounting for this one transient frame using a
      // combination of existing layout extent, new layout extent change and
      // the overlap.
      return;
    }*/
    final bool active = (constraints.remainingPaintExtent > 1.0 || layoutExtent >= (enableInfiniteLoad ? 1.0 : 0.0) * _loadIndicatorExtent);
    // If the list already has a range not larger than the range of the indicator, add the scrolling distance
    final double overscrolledExtent = max(
        constraints.remainingPaintExtent + (constraints.precedingScrollExtent < _loadIndicatorExtent ? constraints.scrollOffset : 0.0),
        0.0);
    // 是否反向
    bool isReverse = constraints.axisDirection == AxisDirection.up || constraints.axisDirection == AxisDirection.left;
    axisDirectionNotifier.value = constraints.axisDirection;
    // Layout the child giving it the space of the currently dragged overscroll
    // which may or may not include a sliver layout extent space that it will
    // keep after the user lets go during the refresh process.
    child!.layout(
      constraints.asBoxConstraints(
        maxExtent: isReverse
            ? overscrolledExtent
            : _hasLayoutExtent || enableInfiniteLoad
                ? max(_loadIndicatorExtent, overscrolledExtent)
                : overscrolledExtent,
      ),
      parentUsesSize: true,
    );
    if (active) {
      geometry = SliverGeometry(
        scrollExtent: layoutExtent,
        paintOrigin: -constraints.scrollOffset,
        paintExtent: max(
          // Check child size (which can come from overscroll) because
          // layoutExtent may be zero. Check layoutExtent also since even
          // with a layoutExtent, the indicator builder may decide to not
          // build anything.
          min(max(childSize, layoutExtent), constraints.remainingPaintExtent) - constraints.scrollOffset,
          0.0,
        ),
        maxPaintExtent: max(
          min(max(childSize, layoutExtent), constraints.remainingPaintExtent) - constraints.scrollOffset,
          0.0,
        ),
        layoutExtent: min(max(layoutExtent - constraints.scrollOffset, 0.0), constraints.remainingPaintExtent),
      );
    } else {
      // If we never started overscrolling, return no geometry.
      geometry = SliverGeometry.zero;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (constraints.remainingPaintExtent > 0.0 || constraints.scrollOffset + childSize > 0) {
      context.paintChild(child!, offset);
    }
  }

  // Nothing special done here because this sliver always paints its child
  // exactly between paintOrigin and paintExtent.
  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {}
}
