import 'dart:math';

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

///The most important method in this file is performLayout, This method controls the drop-down space and layout
///Need know flutter_easyrefresh plugin code source.
///Need know CustomScrollView code data source.
///Need know custom sliver: like this: https://book.flutterchina.club/chapter6/sliver.html#_6-11-1-sliver-%E5%B8%83%E5%B1%80%E5%8D%8F%E8%AE%AE
class PowerRefreshSliverWidget extends SingleChildRenderObjectWidget {
  const PowerRefreshSliverWidget({
    Key? key,
    this.refreshIndicatorLayoutExtent = 0.0,
    this.hasLayoutExtent = false,
    this.enableInfiniteRefresh = false,
    this.headerFloat = false,
    required this.axisDirectionNotifier,
    required this.infiniteRefresh,
    required Widget child,
  })  : assert(refreshIndicatorLayoutExtent >= 0.0),
        super(key: key, child: child);

  // The amount of space the indicator should occupy in the sliver in a
  // resting state when in the refreshing mode.
  final double refreshIndicatorLayoutExtent;

  // _RenderEasyRefreshSliverRefresh will paint the child in the available
  // space either way but this instructs the _RenderEasyRefreshSliverRefresh
  // on whether to also occupy any layoutExtent space or not.
  final bool hasLayoutExtent;

  /// Whether to enable infinite refresh
  final bool enableInfiniteRefresh;

  /// infinite loading callback
  final VoidCallback infiniteRefresh;

  /// Header float like the MaterialHeader
  final bool headerFloat;

  /// list direction
  final ValueNotifier<AxisDirection> axisDirectionNotifier;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return PowerRefreshRenderSliver(
      refreshIndicatorExtent: refreshIndicatorLayoutExtent,
      hasLayoutExtent: hasLayoutExtent,
      enableInfiniteRefresh: enableInfiniteRefresh,
      infiniteRefresh: infiniteRefresh,
      headerFloat: headerFloat,
      axisDirectionNotifier: axisDirectionNotifier,
    );
  }

  @override
  void updateRenderObject(BuildContext context, covariant PowerRefreshRenderSliver renderObject) {
    renderObject
      ..refreshIndicatorLayoutExtent = refreshIndicatorLayoutExtent
      ..hasLayoutExtent = hasLayoutExtent
      ..enableInfiniteRefresh = enableInfiniteRefresh
      ..headerFloat = headerFloat;
  }
}

class PowerRefreshRenderSliver extends RenderSliverSingleBoxAdapter {
  PowerRefreshRenderSliver({
    required double refreshIndicatorExtent,
    required bool hasLayoutExtent,
    required bool enableInfiniteRefresh,
    required this.infiniteRefresh,
    required bool headerFloat,
    required this.axisDirectionNotifier,
    RenderBox? child,
  })  : assert(refreshIndicatorExtent >= 0.0),
        _refreshIndicatorExtent = refreshIndicatorExtent,
        _enableInfiniteRefresh = enableInfiniteRefresh,
        _hasLayoutExtent = hasLayoutExtent,
        _headerFloat = headerFloat {
    this.child = child;
  }

  // The amount of layout space the indicator should occupy in the sliver in a
  // resting state when in the refreshing mode.
  double get refreshIndicatorLayoutExtent => _refreshIndicatorExtent;
  double _refreshIndicatorExtent;

  set refreshIndicatorLayoutExtent(double value) {
    assert(value >= 0.0);
    if (value == _refreshIndicatorExtent) return;
    _refreshIndicatorExtent = value;
    markNeedsLayout();
  }

  /// list direction
  final ValueNotifier<AxisDirection> axisDirectionNotifier;

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

  /// Whether to enable infinite refresh
  bool get enableInfiniteRefresh => _enableInfiniteRefresh;
  bool _enableInfiniteRefresh;

  set enableInfiniteRefresh(bool value) {
    if (value == _enableInfiniteRefresh) return;
    _enableInfiniteRefresh = value;
    markNeedsLayout();
  }

  /// Header float
  bool get headerFloat => _headerFloat;
  bool _headerFloat;

  set headerFloat(bool value) {
    if (value == _headerFloat) return;
    _headerFloat = value;
    markNeedsLayout();
  }

  /// infinite loading callback
  final VoidCallback infiniteRefresh;

  // Trigger infinite refresh
  bool _triggerInfiniteRefresh = false;

  // get Child Size
  double get childSize => constraints.axis == Axis.vertical ? child!.size.height : child!.size.width;

  // This keeps track of the previously applied scroll offsets to the scrollable
  // so that when [refreshIndicatorLayoutExtent] or [hasLayoutExtent] changes,
  // the appropriate delta can be applied to keep everything in the same place
  // visually.
  double layoutExtentOffsetCompensation = 0.0;

  @override
  double get centerOffsetAdjustment {
    // Remove out of bounds when Header is floating
    if (headerFloat) {
      final RenderViewportBase renderViewport = parent! as RenderViewportBase;
      return max(0.0, -renderViewport.offset.pixels);
    }
    return super.centerOffsetAdjustment;
  }

  @override
  void layout(Constraints constraints, {bool parentUsesSize = false}) {
    // When header is floating, and keep on refresh.
    if (headerFloat) {
      final RenderViewportBase renderViewport = parent! as RenderViewportBase;
      super.layout((constraints as SliverConstraints).copyWith(overlap: min(0.0, renderViewport.offset.pixels)), parentUsesSize: true);
    } else {
      super.layout(constraints, parentUsesSize: parentUsesSize);
    }
  }

  ///1. Viewport passes current layout and configuration information to Sliver through SliverConstraints: like this [constraints]
  ///2. Sliver determines its own position, drawing and other information, and saves it in geometry (an object of type SliverGeometry).[geometry]
  ///3. The Viewport reads the information in the geometry to lay out and draw the Sliver. we can find it on the Viewport.
  @override
  void performLayout() {
    // Only pulling to refresh from the top is currently supported.
    // assert(constraints.axisDirection == AxisDirection.down);
    axisDirectionNotifier.value = constraints.axisDirection;
    assert(constraints.growthDirection == GrowthDirection.forward);

    // Determine whether to trigger infinite refresh
    if (enableInfiniteRefresh && constraints.scrollOffset < _refreshIndicatorExtent && constraints.scrollOffset > 0.0) {
      if (!_triggerInfiniteRefresh) {
        _triggerInfiniteRefresh = true;
        infiniteRefresh();
      }
    } else {
      if (constraints.scrollOffset > _refreshIndicatorExtent) {
        if (SchedulerBinding.instance!.schedulerPhase == SchedulerPhase.idle) {
          _triggerInfiniteRefresh = false;
        } else {
          SchedulerBinding.instance!.addPostFrameCallback((Duration timestamp) {
            _triggerInfiniteRefresh = false;
          });
        }
      }
    }

    // The new layout extent this sliver should now have.
    final double layoutExtent = (_hasLayoutExtent || enableInfiniteRefresh ? 1.0 : 0.0) * _refreshIndicatorExtent;
    // If the new layoutExtent instructive changed, the SliverGeometry's
    // layoutExtent will take that value (on the next performLayout run). Shift
    // the scroll offset first so it doesn't make the scroll position suddenly jump.
    // 如果Header浮动则不用过渡
    if (!headerFloat) {
      if (layoutExtent != layoutExtentOffsetCompensation) {
        geometry = SliverGeometry(
          scrollOffsetCorrection: layoutExtent - layoutExtentOffsetCompensation,
        );
        layoutExtentOffsetCompensation = layoutExtent;
        // Return so we don't have to do temporary accounting and adjusting the
        // child's constraints accounting for this one transient frame using a
        // combination of existing layout extent, new layout extent change and
        // the overlap.
        return;
      }
    }
    final bool active = constraints.overlap < 0.0 || layoutExtent > 0.0;
    final double overscrolledExtent = constraints.overlap < 0.0 ? constraints.overlap.abs() : 0.0;
    // Layout the child giving it the space of the currently dragged overscroll
    // which may or may not include a sliver layout extent space that it will
    // keep after the user lets go during the refresh process.
    // The layoutExtent is not required when the Header is floating, otherwise there will be a jump
    if (headerFloat) {
      child!.layout(
        constraints.asBoxConstraints(
          maxExtent: _hasLayoutExtent
              ? overscrolledExtent > _refreshIndicatorExtent
                  ? overscrolledExtent
                  // If it is double.infinity, it will fill the list
                  : _refreshIndicatorExtent == double.infinity
                      ? constraints.viewportMainAxisExtent
                      : _refreshIndicatorExtent
              : overscrolledExtent,
        ),
        parentUsesSize: true,
      );
    } else {
      child!.layout(
        constraints.asBoxConstraints(
          maxExtent: layoutExtent
              // Plus only the overscrolled portion immediately preceding this
              // sliver.
              +
              overscrolledExtent,
        ),
        parentUsesSize: true,
      );
    }
    if (active) {
      // Determine whether the Header is floating
      if (headerFloat) {
        geometry = SliverGeometry(
          scrollExtent: 0.0,
          paintOrigin: 0.0,
          paintExtent: childSize,
          maxPaintExtent: childSize,
          layoutExtent: max(-constraints.scrollOffset, 0.0),
          visible: true,
          hasVisualOverflow: true,
        );
      } else {
        geometry = SliverGeometry(
          scrollExtent: layoutExtent,
          paintOrigin: -overscrolledExtent - constraints.scrollOffset,
          paintExtent: min(
              max(
                // Check child size (which can come from overscroll) because
                // layoutExtent may be zero. Check layoutExtent also since even
                // with a layoutExtent, the indicator builder may decide to not
                // build anything.
                max(childSize, layoutExtent) - constraints.scrollOffset,
                0.0,
              ),
              constraints.remainingPaintExtent),
          maxPaintExtent: max(
            max(childSize, layoutExtent) - constraints.scrollOffset,
            0.0,
          ),
          layoutExtent: max(layoutExtent - constraints.scrollOffset, 0.0),
        );
      }
    } else {
      // If we never started overscrolling, return no geometry.
      geometry = SliverGeometry.zero;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (constraints.overlap < 0.0 || constraints.scrollOffset + childSize > 0) {
      context.paintChild(child!, offset);
    }
  }

  // Nothing special done here because this sliver always paints its child
  // exactly between paintOrigin and paintExtent.
  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {}
}
