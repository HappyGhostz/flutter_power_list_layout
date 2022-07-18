import 'package:flutter/material.dart';
import 'package:flutter_power_list_layout/custom_list/custom_refresh_load_control/power_list_control.dart';
import 'package:flutter_power_list_layout/custom_list/custom_refresh_load_control/task_state.dart';
import 'package:flutter_power_list_layout/custom_list/refresh/power_refresh_layout_widget.dart';

/// Header
abstract class Header {
  /// Header container height
  final double extent;

  /// trigger refresh height
  final double triggerDistance;

  /// whether to float
  final bool float;

  /// completion delay
  final Duration? completeDuration;

  /// Whether to enable infinite refresh
  final bool enableInfiniteRefresh;

  /// Turn on vibration feedback
  final bool enableHapticFeedback;

  /// Out-of-bounds scrolling (enableInfiniteRefresh is true to take effect)
  final bool overScroll;

  Header({
    this.extent = 60.0,
    this.triggerDistance = 70.0,
    this.float = false,
    this.completeDuration,
    this.enableInfiniteRefresh = false,
    this.enableHapticFeedback = false,
    this.overScroll = true,
  });

  Widget builder(
    BuildContext context,
    ValueNotifier<bool> focusNotifier,
    ValueNotifier<TaskState> taskNotifier,
    ValueNotifier<bool> callRefreshNotifier,
    OnRefreshCallback? onRefresh,
    bool taskIndependence,
    bool enableControlFinishRefresh,
    PowerListController? controller,
  ) {
    return PowerRefreshControlWidget(
      refreshIndicatorExtent: extent,
      refreshTriggerPullDistance: triggerDistance,
      builder: contentBuilder,
      completeDuration: completeDuration,
      onRefresh: onRefresh,
      focusNotifier: focusNotifier,
      taskNotifier: taskNotifier,
      callRefreshNotifier: callRefreshNotifier,
      taskIndependence: taskIndependence,
      enableControlFinishRefresh: enableControlFinishRefresh,
      enableInfiniteRefresh: enableInfiniteRefresh && !float,
      enableHapticFeedback: enableHapticFeedback,
      headerFloat: float,
      bindRefreshIndicator: (finishRefresh, resetRefreshState) {
        if (controller != null) {
          controller.finishRefreshCallBack = finishRefresh;
          controller.resetRefreshStateCallBack = resetRefreshState;
        }
      },
    );
  }

  // Header constructor
  Widget contentBuilder(
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
}
