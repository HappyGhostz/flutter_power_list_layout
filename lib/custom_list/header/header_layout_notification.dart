import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_power_list_layout/custom_list/refresh/power_refresh_layout_widget.dart';

class HeaderLayoutNotification extends ChangeNotifier {
  late BuildContext context;
  RefreshIndicatorMode refreshState = RefreshIndicatorMode.inactive;
  double pulledExtent = 0.0;
  late double refreshTriggerPullDistance;
  late double refreshIndicatorExtent;
  late AxisDirection axisDirection;
  late bool float;
  Duration? completeDuration;
  late bool enableInfiniteRefresh;
  bool success = true;
  bool noMore = false;

  void contentBuilder(
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
      bool noMore) {
    this.context = context;
    this.refreshState = refreshState;
    this.pulledExtent = pulledExtent;
    this.refreshTriggerPullDistance = refreshTriggerPullDistance;
    this.refreshIndicatorExtent = refreshIndicatorExtent;
    this.axisDirection = axisDirection;
    this.float = float;
    this.completeDuration = completeDuration;
    this.enableInfiniteRefresh = enableInfiniteRefresh;
    this.success = success;
    this.noMore = noMore;
    SchedulerBinding.instance!.addPostFrameCallback((Duration timestamp) {
      notifyListeners();
    });
  }
}
