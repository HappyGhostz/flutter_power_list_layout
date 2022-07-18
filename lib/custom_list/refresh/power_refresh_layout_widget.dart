import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_power_list_layout/custom_list/custom_refresh_load_control/task_state.dart';
import 'package:flutter_power_list_layout/custom_list/refresh/custom_sliver_refresh_widget.dart';

typedef SliverPowerRefreshWidgetBuilder = Widget Function(
    BuildContext context,
    RefreshIndicatorMode refreshState,
    double pulledExtent,
    double refreshTriggerPullDistance,
    double refreshIndicatorExtent,
    AxisDirection axisDirection,
    bool float,
    Duration? completeDuration,
    bool enableInfiniteRefresh,
    bool success,
    bool noMore);

/// A callback function that's invoked when the [EasyRefreshSliverRefreshControl] is
/// pulled a `refreshTriggerPullDistance`. Must return a [Future]. Upon
/// completion of the [Future], the [EasyRefreshSliverRefreshControl] enters the
/// [RefreshIndicatorMode.done] state and will start to go away.
typedef OnRefreshCallback = Future<void> Function();

/// End refresh
/// success is success (when false, noMore is invalid)
/// noMore is whether there is more data
typedef FinishRefresh = void Function({
  bool success,
  bool noMore,
});

/// Bind refresh indicator
typedef BindRefreshIndicator = void Function(FinishRefresh finishRefresh, VoidCallback resetRefreshState);

enum RefreshIndicatorMode {
  /// Initial state, when not being overscrolled into, or after the overscroll
  /// is canceled or after done and the sliver retracted away.
  inactive,

  /// While being overscrolled but not far enough yet to trigger the refresh.
  drag,

  /// Dragged far enough that the onRefresh callback will run and the dragged
  /// displacement is not yet at the final refresh resting state.
  armed,

  /// While the onRefresh task is running.
  refresh,

  /// finish done
  refreshed,

  /// While the indicator is animating away after refreshing.
  done,
}

class PowerRefreshControlWidget extends StatefulWidget {
  const PowerRefreshControlWidget({
    Key? key,
    this.refreshTriggerPullDistance = _defaultRefreshTriggerPullDistance,
    this.refreshIndicatorExtent = _defaultRefreshIndicatorExtent,
    required this.builder,
    this.completeDuration,
    this.onRefresh,
    required this.focusNotifier,
    required this.taskNotifier,
    required this.callRefreshNotifier,
    required this.taskIndependence,
    required this.bindRefreshIndicator,
    this.enableControlFinishRefresh = false,
    this.enableInfiniteRefresh = false,
    this.enableHapticFeedback = false,
    this.headerFloat = false,
  })  : assert(refreshTriggerPullDistance > 0.0),
        assert(refreshIndicatorExtent >= 0.0),
        assert(
            headerFloat || refreshTriggerPullDistance >= refreshIndicatorExtent,
            'The refresh indicator cannot take more space in its final state '
            'than the amount initially created by overscrolling.'),
        super(key: key);

  /// The amount of overscroll the scrollable must be dragged to trigger a reload.
  ///
  /// Must not be null, must be larger than 0.0 and larger than
  /// [refreshIndicatorExtent]. Defaults to 100px when not specified.
  ///
  /// When overscrolled past this distance, [onRefresh] will be called if not
  /// null and the [builder] will build in the [RefreshIndicatorMode.armed] state.
  final double refreshTriggerPullDistance;

  /// The amount of space the refresh indicator sliver will keep holding while
  /// [onRefresh]'s [Future] is still running.
  ///
  /// Must not be null and must be positive, but can be 0.0, in which case the
  /// sliver will start retracting back to 0.0 as soon as the refresh is started.
  /// Defaults to 60px when not specified.
  ///
  /// Must be smaller than [refreshTriggerPullDistance], since the sliver
  /// shouldn't grow further after triggering the refresh.
  final double refreshIndicatorExtent;

  /// A builder that's called as this sliver's size changes, and as the state
  /// changes.
  ///
  /// A default simple Twitter-style pull-to-refresh indicator is provided if
  /// not specified.
  ///
  /// Can be set to null, in which case nothing will be drawn in the overscrolled
  /// space.
  ///
  /// Will not be called when the available space is zero such as before any
  /// overscroll.
  final SliverPowerRefreshWidgetBuilder builder;

  /// Callback invoked when pulled by [refreshTriggerPullDistance].
  ///
  /// If provided, must return a [Future] which will keep the indicator in the
  /// [RefreshIndicatorMode.refresh] state until the [Future] completes.
  ///
  /// Can be null, in which case a single frame of [RefreshIndicatorMode.armed]
  /// state will be drawn before going immediately to the [RefreshIndicatorMode.done]
  /// where the sliver will start retracting.
  final OnRefreshCallback? onRefresh;

  /// completion delay
  final Duration? completeDuration;

  /// Bind refresh indicator
  final BindRefreshIndicator bindRefreshIndicator;

  /// Whether to open the control end
  final bool enableControlFinishRefresh;

  /// Whether to enable infinite refresh
  final bool enableInfiniteRefresh;

  /// Turn on vibration feedback
  final bool enableHapticFeedback;

  /// scroll state
  final ValueNotifier<bool> focusNotifier;

  /// trigger refresh state
  final ValueNotifier<bool> callRefreshNotifier;

  /// task status
  final ValueNotifier<TaskState> taskNotifier;

  /// Whether the task is independent
  final bool taskIndependence;

  /// Header float
  final bool headerFloat;

  static const double _defaultRefreshTriggerPullDistance = 100.0;
  static const double _defaultRefreshIndicatorExtent = 60.0;

  /// Retrieve the current state of the EasyRefreshSliverRefreshControl. The same as the
  /// state that gets passed into the [builder] function. Used for testing.
  /*@visibleForTesting
  static RefreshIndicatorMode state(BuildContext context) {
    final _EasyRefreshSliverRefreshControlState state = context
        .findAncestorStateOfType<_EasyRefreshSliverRefreshControlState>();
    return state.refreshState;
  }*/

  @override
  State<StatefulWidget> createState() => _PowerRefreshControlWidgetState();
}

class _PowerRefreshControlWidgetState extends State<PowerRefreshControlWidget> {
  // Reset the state from done to inactive when only this fraction of the
  // original `refreshTriggerPullDistance` is left.
  static const double _inactiveResetOverscrollFraction = 0.1;

  RefreshIndicatorMode refreshState = RefreshIndicatorMode.inactive;

  // [Future] returned by the widget's `onRefresh`.
  Future<void>? _refreshTask;

  Future<void>? get refreshTask => _refreshTask;

  bool get hasTask {
    return widget.taskIndependence ? _refreshTask != null : widget.taskNotifier.value.loading || widget.taskNotifier.value.refreshing;
  }

  set refreshTask(Future<void>? task) {
    _refreshTask = task;
    if (!widget.taskIndependence && task != null) {
      widget.taskNotifier.value = widget.taskNotifier.value.copy(refreshing: true);
    }
    if (!widget.taskIndependence && task == null && widget.refreshIndicatorExtent == double.infinity) {
      widget.taskNotifier.value = widget.taskNotifier.value.copy(refreshing: false);
    }
  }

  // The amount of space available from the inner indicator box's perspective.
  //
  // The value is the sum of the sliver's layout extent and the overscroll
  // (which partially gets transferred into the layout extent when the refresh
  // triggers).
  //
  // The value of latestIndicatorBoxExtent doesn't change when the sliver scrolls
  // away without retracting; it is independent from the sliver's scrollOffset.
  double latestIndicatorBoxExtent = 0.0;
  bool hasSliverLayoutExtent = false;

  // scroll focus
  bool get _focus => widget.focusNotifier.value;

  // refresh success
  bool _success = true;

  // no more data
  bool _noMore = false;

  // list direction
  late ValueNotifier<AxisDirection> _axisDirectionNotifier;

  @override
  void initState() {
    super.initState();
    refreshState = RefreshIndicatorMode.inactive;
    _axisDirectionNotifier = ValueNotifier<AxisDirection>(AxisDirection.down);
    // bind refresh indicator
    widget.bindRefreshIndicator(finishRefresh, resetRefreshState);
    widget.callRefreshNotifier.addListener(() {
      if (widget.callRefreshNotifier.value) {
        refreshState = RefreshIndicatorMode.inactive;
      }
    });
    // listener start refresh
    widget.taskNotifier.addListener(() {
      if (widget.taskNotifier.value.loading && !widget.taskIndependence) {
        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  @override
  void dispose() {
    _axisDirectionNotifier.dispose();
    super.dispose();
  }

  void finishRefresh({
    bool success = true,
    bool noMore = false,
  }) {
    _success = success;
    _noMore = _success == false ? false : noMore;
    widget.taskNotifier.value = widget.taskNotifier.value.copy(refreshNoMore: _noMore);
    if (widget.enableControlFinishRefresh && refreshTask != null) {
      if (widget.enableInfiniteRefresh) {
        refreshState = RefreshIndicatorMode.inactive;
      }
      setState(() => refreshTask = null);
      refreshState = transitionNextState();
    }
  }

  void resetRefreshState() {
    if (mounted) {
      setState(() {
        _success = true;
        _noMore = false;
        refreshState = RefreshIndicatorMode.inactive;
        hasSliverLayoutExtent = false;
      });
    }
  }

  void _infiniteRefresh() {
    if (widget.callRefreshNotifier.value) {
      widget.callRefreshNotifier.value = false;
    }
    if (!hasTask && widget.enableInfiniteRefresh && _noMore != true) {
      if (widget.enableHapticFeedback) {
        HapticFeedback.mediumImpact();
      }
      SchedulerBinding.instance!.addPostFrameCallback((Duration timestamp) {
        refreshState = RefreshIndicatorMode.refresh;
        refreshTask = widget.onRefresh!()
          ..then((_) {
            if (mounted && !widget.enableControlFinishRefresh) {
              refreshState = RefreshIndicatorMode.refresh;
              setState(() => refreshTask = null);
              // Trigger one more transition because by this time, BoxConstraint's
              // maxHeight might already be resting at 0 in which case no
              // calls to [transitionNextState] will occur anymore and the
              // state may be stuck in a non-inactive state.
              refreshState = transitionNextState();
            }
          });
        setState(() => hasSliverLayoutExtent = true);
      });
    }
  }

  // A state machine transition calculator. Multiple states can be transitioned
  // through per single call.
  RefreshIndicatorMode transitionNextState() {
    RefreshIndicatorMode nextState = RefreshIndicatorMode.inactive;

    // Judge if there is no more
    if (_noMore == true && widget.enableInfiniteRefresh) {
      return refreshState;
    } else if (_noMore == true &&
        refreshState != RefreshIndicatorMode.refresh &&
        refreshState != RefreshIndicatorMode.refreshed &&
        refreshState != RefreshIndicatorMode.done) {
      return refreshState;
    } else if (widget.enableInfiniteRefresh && refreshState == RefreshIndicatorMode.done) {
      return RefreshIndicatorMode.inactive;
    }

    // end
    void goToDone() {
      nextState = RefreshIndicatorMode.done;
      refreshState = RefreshIndicatorMode.done;
      // Either schedule the RenderSliver to re-layout on the next frame
      // when not currently in a frame or schedule it on the next frame.
      if (SchedulerBinding.instance!.schedulerPhase == SchedulerPhase.idle) {
        setState(() => hasSliverLayoutExtent = false);
      } else {
        SchedulerBinding.instance!.addPostFrameCallback((Duration timestamp) {
          if (mounted) setState(() => hasSliverLayoutExtent = false);
        });
      }
      if (!widget.taskIndependence) {
        widget.taskNotifier.value = widget.taskNotifier.value.copy(refreshing: false);
      }
    }

    // done
    RefreshIndicatorMode? goToFinish() {
      RefreshIndicatorMode state = RefreshIndicatorMode.refreshed;
      if (widget.completeDuration == null || widget.enableInfiniteRefresh) {
        goToDone();
        return null;
      } else {
        Future.delayed(widget.completeDuration!, () {
          if (mounted) {
            goToDone();
          }
        });
        return state;
      }
    }

    switch (refreshState) {
      case RefreshIndicatorMode.inactive:
        if (latestIndicatorBoxExtent <= 0 || (!_focus && !widget.callRefreshNotifier.value)) {
          return RefreshIndicatorMode.inactive;
        } else {
          nextState = RefreshIndicatorMode.drag;
        }
        continue drag;
      drag:
      case RefreshIndicatorMode.drag:
        if (latestIndicatorBoxExtent == 0) {
          return RefreshIndicatorMode.inactive;
        } else if (latestIndicatorBoxExtent <= widget.refreshTriggerPullDistance) {
          // Cancel fixed height if refresh is not triggered
          if (hasSliverLayoutExtent && !hasTask) {
            SchedulerBinding.instance!.addPostFrameCallback((Duration timestamp) {
              setState(() => hasSliverLayoutExtent = false);
            });
          }
          return RefreshIndicatorMode.drag;
        } else {
          // Fix the height in advance to prevent the list from rebounding
          SchedulerBinding.instance!.addPostFrameCallback((Duration timestamp) {
            if (!hasSliverLayoutExtent) {
              if (mounted) setState(() => hasSliverLayoutExtent = true);
            }
          });
          if (widget.onRefresh != null && !hasTask) {
            if (!_focus) {
              if (widget.callRefreshNotifier.value) {
                widget.callRefreshNotifier.value = false;
              }
              if (widget.enableHapticFeedback) {
                HapticFeedback.mediumImpact();
              }
              // trigger refresh task
              SchedulerBinding.instance!.addPostFrameCallback((Duration timestamp) {
                refreshTask = widget.onRefresh!()
                  ..then((_) {
                    if (mounted && !widget.enableControlFinishRefresh) {
                      if (widget.enableInfiniteRefresh) {
                        refreshState = RefreshIndicatorMode.inactive;
                      }
                      setState(() => refreshTask = null);
                      if (!widget.enableInfiniteRefresh) refreshState = transitionNextState();
                    }
                  });
              });
              return RefreshIndicatorMode.armed;
            }
            return RefreshIndicatorMode.drag;
          }
          return RefreshIndicatorMode.drag;
        }
      // Don't continue here. We can never possibly call onRefresh and
      // progress to the next state in one [computeNextState] call.
      //break;
      case RefreshIndicatorMode.armed:
        if (refreshState == RefreshIndicatorMode.armed && !hasTask) {
          // done
          var state = goToFinish();
          if (state != null) return state;
          continue done;
        }

        if (latestIndicatorBoxExtent != widget.refreshIndicatorExtent) {
          return RefreshIndicatorMode.armed;
        } else {
          nextState = RefreshIndicatorMode.refresh;
        }
        continue refresh;
      refresh:
      case RefreshIndicatorMode.refresh:
        if (refreshTask != null) {
          return RefreshIndicatorMode.refresh;
        } else {
          // finish
          var state = goToFinish();
          if (state != null) return state;
        }
        continue done;
      done:
      case RefreshIndicatorMode.done:
        // Let the transition back to inactive trigger before strictly going
        // to 0.0 since the last bit of the animation can take some time and
        // can feel sluggish if not going all the way back to 0.0 prevented
        // a subsequent pull-to-refresh from starting.
        if (latestIndicatorBoxExtent > widget.refreshTriggerPullDistance * _inactiveResetOverscrollFraction) {
          return RefreshIndicatorMode.done;
        } else {
          nextState = RefreshIndicatorMode.inactive;
        }
        break;
      case RefreshIndicatorMode.refreshed:
        nextState = refreshState;
        break;
      default:
        break;
    }

    return nextState;
  }

  @override
  Widget build(BuildContext context) {
    return PowerRefreshSliverWidget(
      refreshIndicatorLayoutExtent: widget.refreshIndicatorExtent,
      hasLayoutExtent: hasSliverLayoutExtent,
      enableInfiniteRefresh: widget.enableInfiniteRefresh,
      infiniteRefresh: _infiniteRefresh,
      headerFloat: widget.headerFloat,
      axisDirectionNotifier: _axisDirectionNotifier,
      // A LayoutBuilder lets the sliver's layout changes be fed back out to
      // its owner to trigger state changes.
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          // Determine if there is a loading task
          if (!widget.taskIndependence && widget.taskNotifier.value.loading) {
            return const SizedBox();
          }
          // Is it vertical
          bool isVertical = _axisDirectionNotifier.value == AxisDirection.down || _axisDirectionNotifier.value == AxisDirection.up;
          latestIndicatorBoxExtent = isVertical ? constraints.maxHeight : constraints.maxWidth;
          refreshState = transitionNextState();
          if (latestIndicatorBoxExtent >= 0) {
            return widget.builder(
              context,
              refreshState,
              latestIndicatorBoxExtent,
              widget.refreshTriggerPullDistance,
              widget.refreshIndicatorExtent,
              _axisDirectionNotifier.value,
              widget.headerFloat,
              widget.completeDuration,
              widget.enableInfiniteRefresh,
              _success,
              _noMore,
            );
          }
          return Container();
        },
      ),
    );
  }
}
