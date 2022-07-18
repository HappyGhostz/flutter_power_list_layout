import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_power_list_layout/custom_list/load/power_load_layout_widget.dart';

class FooterLayoutNotification extends ChangeNotifier {
  late BuildContext context;
  LoadIndicatorMode loadState = LoadIndicatorMode.inactive;
  double pulledExtent = 0.0;
  late double loadTriggerPullDistance;
  late double loadIndicatorExtent;
  late AxisDirection axisDirection;
  late bool float;
  Duration? completeDuration;
  late bool enableInfiniteLoad;
  bool success = true;
  bool noMore = false;

  void contentBuilder(
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
      bool noMore) {
    this.context = context;
    this.loadState = loadState;
    this.pulledExtent = pulledExtent;
    this.loadTriggerPullDistance = loadTriggerPullDistance;
    this.loadIndicatorExtent = loadIndicatorExtent;
    this.axisDirection = axisDirection;
    this.float = float;
    this.completeDuration = completeDuration;
    this.enableInfiniteLoad = enableInfiniteLoad;
    this.success = success;
    this.noMore = noMore;
    SchedulerBinding.instance!.addPostFrameCallback((Duration timestamp) {
      notifyListeners();
    });
  }
}
