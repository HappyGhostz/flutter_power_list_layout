import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_power_list_layout/custom_list/custom_refresh_load_control/task_state.dart';
import 'package:flutter_power_list_layout/custom_list/load/custom_sliver_load_widget.dart';

/// Signature for a builder that can create a different widget to show in the
/// refresh indicator space depending on the current state of the refresh
/// control and the space available.
///
/// The `loadTriggerPullDistance` and `loadIndicatorExtent` parameters are
/// the same values passed into the [EasyRefreshSliverLoadControl].
///
/// The `pulledExtent` parameter is the currently available space either from
/// overscrolling or as held by the sliver during refresh.
typedef SliverPowerLoadWidgetBuilder = Widget Function(
    BuildContext context,
    LoadIndicatorMode loadState,
    double pulledExtent,
    double loadTriggerPullDistance,
    double loadIndicatorExtent,
    AxisDirection axisDirection,
    bool float,
    Duration? completeDuration,
    bool enableInfiniteLoad,
    bool success,
    bool noMore);

/// A callback function that's invoked when the [EasyRefreshSliverLoadControl] is
/// pulled a `loadTriggerPullDistance`. Must return a [Future]. Upon
/// completion of the [Future], the [EasyRefreshSliverLoadControl] enters the
/// [LoadIndicatorMode.done] state and will start to go away.
typedef OnLoadCallback = Future<void> Function();

/// end loading
/// success is success (when false, noMore is invalid)
/// noMore is whether there is more data
typedef FinishLoad = void Function({
  bool success,
  bool noMore,
});

/// Bind the load indicator
typedef BindLoadIndicator = void Function(FinishLoad finishLoad, VoidCallback resetLoadState);

/// The current state of the refresh control.
///
/// Passed into the [LoadControlBuilder] builder function so
/// users can show different UI in different modes.
enum LoadIndicatorMode {
  /// Initial state, when not being overscrolled into, or after the overscroll
  /// is canceled or after done and the sliver retracted away.
  inactive,

  /// While being overscrolled but not far enough yet to trigger the refresh.
  drag,

  /// Dragged far enough that the onLoad callback will run and the dragged
  /// displacement is not yet at the final refresh resting state.
  armed,

  /// While the onLoad task is running.
  load,

  /// load done
  loaded,

  /// While the indicator is animating away after refreshing.
  done,
}

class PowerLoadControlWidget extends StatefulWidget {
  /// Create a new refresh control for inserting into a list of slivers.
  ///
  /// The [loadTriggerPullDistance] and [loadIndicatorExtent] arguments
  /// must not be null and must be >= 0.
  ///
  /// The [builder] argument may be null, in which case no indicator UI will be
  /// shown but the [onLoad] will still be invoked. By default, [builder]
  /// shows a [CupertinoActivityIndicator].
  ///
  /// The [onLoad] argument will be called when pulled far enough to trigger
  /// a refresh.
  const PowerLoadControlWidget({
    Key? key,
    this.loadTriggerPullDistance = _defaultLoadTriggerPullDistance,
    this.loadIndicatorExtent = _defaultLoadIndicatorExtent,
    required this.builder,
    this.completeDuration,
    this.onLoad,
    required this.focusNotifier,
    required this.taskNotifier,
    required this.callLoadNotifier,
    required this.taskIndependence,
    required this.extraExtentNotifier,
    required this.bindLoadIndicator,
    this.enableControlFinishLoad = false,
    this.enableInfiniteLoad = false,
    this.enableHapticFeedback = false,
    this.footerFloat = false,
    this.safeArea = false,
    this.padding,
  })  : assert(loadTriggerPullDistance > 0.0),
        assert(loadIndicatorExtent >= 0.0),
        assert(
            loadTriggerPullDistance >= loadIndicatorExtent,
            'The refresh indicator cannot take more space in its final state '
            'than the amount initially created by overscrolling.'),
        super(key: key);

  /// The amount of overscroll the scrollable must be dragged to trigger a reload.
  ///
  /// Must not be null, must be larger than 0.0 and larger than
  /// [loadIndicatorExtent]. Defaults to 100px when not specified.
  ///
  /// When overscrolled past this distance, [onLoad] will be called if not
  /// null and the [builder] will build in the [LoadIndicatorMode.armed] state.
  final double loadTriggerPullDistance;

  /// The amount of space the refresh indicator sliver will keep holding while
  /// [onLoad]'s [Future] is still running.
  ///
  /// Must not be null and must be positive, but can be 0.0, in which case the
  /// sliver will start retracting back to 0.0 as soon as the refresh is started.
  /// Defaults to 60px when not specified.
  ///
  /// Must be smaller than [loadTriggerPullDistance], since the sliver
  /// shouldn't grow further after triggering the refresh.
  final double loadIndicatorExtent;

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
  final SliverPowerLoadWidgetBuilder builder;

  /// Callback invoked when pulled by [loadTriggerPullDistance].
  ///
  /// If provided, must return a [Future] which will keep the indicator in the
  /// [LoadIndicatorMode.refresh] state until the [Future] completes.
  ///
  /// Can be null, in which case a single frame of [LoadIndicatorMode.armed]
  /// state will be drawn before going immediately to the [LoadIndicatorMode.done]
  /// where the sliver will start retracting.
  final OnLoadCallback? onLoad;

  /// completion delay
  final Duration? completeDuration;

  /// Bind loading indicator
  final BindLoadIndicator bindLoadIndicator;

  /// Whether to open the control end
  final bool enableControlFinishLoad;

  /// Whether to enable infinite loading
  final bool enableInfiniteLoad;

  /// Turn on vibration feedback
  final bool enableHapticFeedback;

  /// scroll state
  final ValueNotifier<bool> focusNotifier;

  /// task status
  final ValueNotifier<TaskState> taskNotifier;

  /// trigger loading state
  final ValueNotifier<bool> callLoadNotifier;

  /// Extra length when the list is not full
  final ValueNotifier<double> extraExtentNotifier;

  /// Whether the task is independent
  final bool taskIndependence;

  /// Footer float
  final bool footerFloat;

  /// safe area
  final bool safeArea;

  /// Padding (use it reasonably according to the layout, safeArea is invalid after setting)
  final EdgeInsets? padding;

  static const double _defaultLoadTriggerPullDistance = 100.0;
  static const double _defaultLoadIndicatorExtent = 60.0;

  /// Retrieve the current state of the EasyRefreshSliverLoadControl. The same as the
  /// state that gets passed into the [builder] function. Used for testing.
  /*@visibleForTesting
  static LoadIndicatorMode state(BuildContext context) {
    final _EasyRefreshSliverLoadControlState state =
        context.findAncestorStateOfType<_EasyRefreshSliverLoadControlState>();
    return state.loadState;
  }*/

  @override
  PowerLoadControlWidgetState createState() => PowerLoadControlWidgetState();
}

class PowerLoadControlWidgetState extends State<PowerLoadControlWidget> {
  // Reset the state from done to inactive when only this fraction of the
  // original `loadTriggerPullDistance` is left.
  static const double _inactiveResetOverscrollFraction = 0.1;

  LoadIndicatorMode loadState = LoadIndicatorMode.inactive;

  // [Future] returned by the widget's `onLoad`.
  Future<void>? _loadTask;

  set loadTask(Future<void>? task) {
    _loadTask = task;
    if (!widget.taskIndependence) {
      widget.taskNotifier.value = widget.taskNotifier.value.copy(loading: task != null);
    }
  }

  Future<void>? get loadTask => _loadTask;

  bool get hasTask {
    return widget.taskIndependence ? loadTask != null : widget.taskNotifier.value.refreshing || widget.taskNotifier.value.loading;
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

  // refresh completed
  bool _success = true;

  // no more data
  bool _noMore = false;

  // list direction
  late ValueNotifier<AxisDirection> _axisDirectionNotifier;

  @override
  void initState() {
    super.initState();
    _axisDirectionNotifier = ValueNotifier<AxisDirection>(AxisDirection.down);
    _axisDirectionNotifier.addListener(() {
      SchedulerBinding.instance!.addPostFrameCallback((Duration timestamp) {
        if (mounted) setState(() {});
      });
    });
    widget.bindLoadIndicator(finishLoad, resetLoadState);
    widget.callLoadNotifier.addListener(() {
      if (widget.callLoadNotifier.value) {
        loadState = LoadIndicatorMode.inactive;
      }
    });
    widget.taskNotifier.addListener(() {
      if (widget.taskNotifier.value.refreshing && !widget.taskIndependence) {
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

  void finishLoad({
    bool success = true,
    bool noMore = false,
  }) {
    _success = success;
    _noMore = _success == false ? false : noMore;
    widget.taskNotifier.value = widget.taskNotifier.value.copy(loadNoMore: _noMore);
    if (widget.enableControlFinishLoad && loadTask != null) {
      if (widget.enableInfiniteLoad) {
        loadState = LoadIndicatorMode.inactive;
      }
      setState(() => loadTask = null);
      loadState = transitionNextState();
    }
  }

  void resetLoadState() {
    if (mounted) {
      setState(() {
        _success = true;
        _noMore = false;
        loadState = LoadIndicatorMode.inactive;
        hasSliverLayoutExtent = false;
      });
    }
  }

  // 无限加载
  void _infiniteLoad() {
    if (widget.callLoadNotifier.value) {
      widget.callLoadNotifier.value = false;
    }
    if (!hasTask && widget.enableInfiniteLoad && _noMore != true) {
      if (widget.enableHapticFeedback) {
        HapticFeedback.mediumImpact();
      }
      SchedulerBinding.instance!.addPostFrameCallback((Duration timestamp) {
        loadState = LoadIndicatorMode.load;
        loadTask = widget.onLoad!()
          ..then((_) {
            if (mounted && !widget.enableControlFinishLoad) {
              loadState = LoadIndicatorMode.load;
              setState(() => loadTask = null);
              // Trigger one more transition because by this time, BoxConstraint's
              // maxHeight might already be resting at 0 in which case no
              // calls to [transitionNextState] will occur anymore and the
              // state may be stuck in a non-inactive state.
              loadState = transitionNextState();
            }
          });
        setState(() => hasSliverLayoutExtent = true);
      });
    }
  }

  // A state machine transition calculator. Multiple states can be transitioned
  // through per single call.
  LoadIndicatorMode transitionNextState() {
    LoadIndicatorMode nextState = LoadIndicatorMode.inactive;

    // 判断是否没有更多
    if (_noMore == true && widget.enableInfiniteLoad) {
      return loadState;
    } else if (_noMore == true &&
        loadState != LoadIndicatorMode.load &&
        loadState != LoadIndicatorMode.loaded &&
        loadState != LoadIndicatorMode.done) {
      return loadState;
    } else if (widget.enableInfiniteLoad && loadState == LoadIndicatorMode.done) {
      return LoadIndicatorMode.inactive;
    }

    // 完成
    void goToDone() {
      nextState = LoadIndicatorMode.done;
      loadState = LoadIndicatorMode.done;
      // Either schedule the RenderSliver to re-layout on the next frame
      // when not currently in a frame or schedule it on the next frame.
      if (SchedulerBinding.instance!.schedulerPhase == SchedulerPhase.idle) {
        setState(() => hasSliverLayoutExtent = false);
      } else {
        SchedulerBinding.instance!.addPostFrameCallback((Duration timestamp) {
          if (mounted) setState(() => hasSliverLayoutExtent = false);
        });
      }
      if (!widget.taskIndependence) widget.taskNotifier.value = widget.taskNotifier.value.copy(loading: loadTask != null);
    }

    LoadIndicatorMode? goToFinish() {
      LoadIndicatorMode state = LoadIndicatorMode.loaded;
      if (widget.completeDuration == null || widget.enableInfiniteLoad) {
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

    switch (loadState) {
      case LoadIndicatorMode.inactive:
        if (latestIndicatorBoxExtent <= 0 || (!_focus && !widget.callLoadNotifier.value)) {
          return LoadIndicatorMode.inactive;
        } else {
          nextState = LoadIndicatorMode.drag;
        }
        continue drag;
      drag:
      case LoadIndicatorMode.drag:
        if (latestIndicatorBoxExtent == 0) {
          return LoadIndicatorMode.inactive;
        } else if (latestIndicatorBoxExtent <= widget.loadTriggerPullDistance) {
          if (hasSliverLayoutExtent && !hasTask) {
            SchedulerBinding.instance!.addPostFrameCallback((Duration timestamp) {
              setState(() => hasSliverLayoutExtent = false);
            });
          }
          return LoadIndicatorMode.drag;
        } else {
          SchedulerBinding.instance!.addPostFrameCallback((Duration timestamp) {
            if (!hasSliverLayoutExtent) {
              if (mounted) setState(() => hasSliverLayoutExtent = true);
            }
          });
          if (widget.onLoad != null && !hasTask) {
            if (!_focus) {
              if (widget.enableHapticFeedback) {
                HapticFeedback.mediumImpact();
              }
              SchedulerBinding.instance!.addPostFrameCallback((Duration timestamp) {
                loadTask = widget.onLoad!()
                  ..then((_) {
                    if (mounted && !widget.enableControlFinishLoad) {
                      if (widget.enableInfiniteLoad) {
                        loadState = LoadIndicatorMode.inactive;
                      }
                      setState(() => loadTask = null);
                      if (!widget.enableInfiniteLoad) loadState = transitionNextState();
                    }
                  });
              });
              return LoadIndicatorMode.armed;
            }
            return LoadIndicatorMode.drag;
          }
          return LoadIndicatorMode.drag;
        }
      // Don't continue here. We can never possibly call onLoad and
      // progress to the next state in one [computeNextState] call.
      //break;
      case LoadIndicatorMode.armed:
        if (loadState == LoadIndicatorMode.armed && !hasTask) {
          var state = goToFinish();
          if (state != null) return state;
          continue done;
        }

        if (latestIndicatorBoxExtent > widget.loadIndicatorExtent) {
          return LoadIndicatorMode.armed;
        } else {
          nextState = LoadIndicatorMode.load;
        }
        continue refresh;
      refresh:
      case LoadIndicatorMode.load:
        if (loadTask != null) {
          return LoadIndicatorMode.load;
        } else {
          var state = goToFinish();
          if (state != null) return state;
        }
        continue done;
      done:
      case LoadIndicatorMode.done:
        // Let the transition back to inactive trigger before strictly going
        // to 0.0 since the last bit of the animation can take some time and
        // can feel sluggish if not going all the way back to 0.0 prevented
        // a subsequent pull-to-refresh from starting.
        if (latestIndicatorBoxExtent > widget.loadTriggerPullDistance * _inactiveResetOverscrollFraction) {
          return LoadIndicatorMode.done;
        } else {
          nextState = LoadIndicatorMode.inactive;
        }
        break;
      case LoadIndicatorMode.loaded:
        nextState = loadState;
        break;
      default:
        break;
    }

    return nextState;
  }

  EdgeInsets get _padding {
    if (widget.padding != null) {
      return widget.padding!;
    }
    if (!widget.safeArea) {
      return EdgeInsets.zero;
    } else {
      return EdgeInsets.only(
        top: widget.safeArea && _axisDirectionNotifier.value == AxisDirection.up ? MediaQuery.of(context).padding.top : 0.0,
        bottom: widget.safeArea && _axisDirectionNotifier.value == AxisDirection.down ? MediaQuery.of(context).padding.bottom : 0.0,
        left: widget.safeArea && _axisDirectionNotifier.value == AxisDirection.left ? MediaQuery.of(context).padding.left : 0.0,
        right: widget.safeArea && _axisDirectionNotifier.value == AxisDirection.right ? MediaQuery.of(context).padding.right : 0.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: _padding,
      sliver: PowerLoadSliverWidget(
        loadIndicatorLayoutExtent: widget.loadIndicatorExtent,
        hasLayoutExtent: hasSliverLayoutExtent,
        enableInfiniteLoad: widget.enableInfiniteLoad,
        infiniteLoad: _infiniteLoad,
        extraExtentNotifier: widget.extraExtentNotifier,
        footerFloat: widget.footerFloat,
        axisDirectionNotifier: _axisDirectionNotifier,
        // A LayoutBuilder lets the sliver's layout changes be fed back out to
        // its owner to trigger state changes.
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            if (!widget.taskIndependence && widget.taskNotifier.value.refreshing) {
              return const SizedBox();
            }
            bool isVertical = _axisDirectionNotifier.value == AxisDirection.down || _axisDirectionNotifier.value == AxisDirection.up;
            bool isReverse = _axisDirectionNotifier.value == AxisDirection.up || _axisDirectionNotifier.value == AxisDirection.left;
            latestIndicatorBoxExtent = (isVertical ? constraints.maxHeight : constraints.maxWidth) - widget.extraExtentNotifier.value;
            loadState = transitionNextState();
            if (widget.extraExtentNotifier.value > 0.0 && loadState == LoadIndicatorMode.loaded && loadTask == null) {
              loadState = LoadIndicatorMode.inactive;
            }
            if (latestIndicatorBoxExtent >= 0) {
              Widget child = widget.builder(
                context,
                loadState,
                latestIndicatorBoxExtent,
                widget.loadTriggerPullDistance,
                widget.loadIndicatorExtent,
                _axisDirectionNotifier.value,
                widget.footerFloat,
                widget.completeDuration,
                widget.enableInfiniteLoad,
                _success,
                _noMore,
              );
              return isVertical
                  ? Column(
                      children: <Widget>[
                        isReverse
                            ? const SizedBox()
                            : const Expanded(
                                flex: 1,
                                child: SizedBox(),
                              ),
                        SizedBox(
                          height: latestIndicatorBoxExtent,
                          child: child,
                        ),
                        !isReverse
                            ? const SizedBox()
                            : const Expanded(
                                flex: 1,
                                child: SizedBox(),
                              ),
                      ],
                    )
                  : Row(
                      children: <Widget>[
                        isReverse
                            ? const SizedBox()
                            : const Expanded(
                                flex: 1,
                                child: SizedBox(),
                              ),
                        SizedBox(
                          width: latestIndicatorBoxExtent,
                          child: child,
                        ),
                        !isReverse
                            ? const SizedBox()
                            : const Expanded(
                                flex: 1,
                                child: SizedBox(),
                              ),
                      ],
                    );
            }
            return Container();
          },
        ),
      ),
    );
  }
}
