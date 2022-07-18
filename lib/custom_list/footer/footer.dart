import 'package:flutter/material.dart';
import 'package:flutter_power_list_layout/custom_list/custom_refresh_load_control/power_list_control.dart';
import 'package:flutter_power_list_layout/custom_list/custom_refresh_load_control/task_state.dart';
import 'package:flutter_power_list_layout/custom_list/load/power_load_layout_widget.dart';

/// Header
abstract class Footer {
  /// Footer height
  final double extent;

  /// Height (over this height triggers loading)
  final double triggerDistance;
  @Deprecated('No solution has been found yet, the settings are invalid')
  final bool float;

  // completion delay
  final Duration? completeDuration;

  /// Whether to enable infinite loading
  final bool enableInfiniteLoad;

  /// Turn on vibration feedback
  final bool enableHapticFeedback;

  /// Out-of-bounds scrolling (enableInfiniteLoad is true to take effect)
  final bool overScroll;

  /// safe area
  final bool safeArea;

  /// Padding (use it reasonably according to the layout, safeArea is invalid after setting)
  final EdgeInsets? padding;

  Footer({
    this.extent = 60.0,
    this.triggerDistance = 70.0,
    this.float = false,
    this.completeDuration,
    this.enableInfiniteLoad = false,
    this.enableHapticFeedback = false,
    this.overScroll = false,
    this.safeArea = false,
    this.padding,
  });

  // 构造器
  Widget builder(
    BuildContext context,
    ValueNotifier<bool> focusNotifier,
    ValueNotifier<TaskState> taskNotifier,
    ValueNotifier<bool> callLoadNotifier,
    ValueNotifier<double> extraExtentNotifier,
    OnLoadCallback? onLoad,
    bool taskIndependence,
    bool enableControlFinishLoad,
    PowerListController? controller,
  ) {
    return PowerLoadControlWidget(
      loadIndicatorExtent: extent,
      loadTriggerPullDistance: triggerDistance,
      builder: contentBuilder,
      completeDuration: completeDuration,
      onLoad: onLoad,
      focusNotifier: focusNotifier,
      taskNotifier: taskNotifier,
      extraExtentNotifier: extraExtentNotifier,
      callLoadNotifier: callLoadNotifier,
      taskIndependence: taskIndependence,
      enableControlFinishLoad: enableControlFinishLoad,
      enableInfiniteLoad: enableInfiniteLoad,
      //enableInfiniteLoad: enableInfiniteLoad && !float,
      enableHapticFeedback: enableHapticFeedback,
      //footerFloat: float,
      safeArea: safeArea,
      padding: padding,
      bindLoadIndicator: (finishLoad, resetLoadState) {
        if (controller != null) {
          controller.finishLoadCallBack = finishLoad;
          controller.resetLoadStateCallBack = resetLoadState;
        }
      },
    );
  }

  // Header构造器
  Widget contentBuilder(
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
}
