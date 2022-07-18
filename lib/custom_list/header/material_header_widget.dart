import 'package:flutter/material.dart';
import 'package:flutter_power_list_layout/custom_list/header/header.dart';
import 'package:flutter_power_list_layout/custom_list/header/header_layout_notification.dart';
import 'package:flutter_power_list_layout/custom_list/refresh/power_refresh_layout_widget.dart';

// The duration of the ScaleTransition that starts when the refresh action
// has completed.
const Duration _kIndicatorScaleDuration = Duration(milliseconds: 200);

/// Texture design Header component
class MaterialHeader extends Header {
  final Key? key;
  final double displacement;

  final Animation<Color?>? valueColor;

  final Color? backgroundColor;

  final HeaderLayoutNotification headerLayoutNotification = HeaderLayoutNotification();

  MaterialHeader({
    this.key,
    this.displacement = 40.0,
    this.valueColor,
    this.backgroundColor,
    completeDuration = const Duration(seconds: 1),
    bool enableHapticFeedback = false,
  }) : super(
          float: true,
          extent: 70.0,
          triggerDistance: 70.0,
          enableHapticFeedback: enableHapticFeedback,
        );

  @override
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
      bool noMore) {
    headerLayoutNotification.contentBuilder(context, refreshState, pulledExtent, refreshTriggerPullDistance, refreshIndicatorExtent,
        axisDirection, float, completeDuration, enableInfiniteRefresh, success, noMore);
    return MaterialHeaderWidget(
      key: key,
      displacement: displacement,
      valueColor: valueColor,
      backgroundColor: backgroundColor,
      headerLayoutNotification: headerLayoutNotification,
    );
  }
}

/// Texture design Header component
class MaterialHeaderWidget extends StatefulWidget {
  final double displacement;

  final Animation<Color?>? valueColor;

  final Color? backgroundColor;
  final HeaderLayoutNotification headerLayoutNotification;

  const MaterialHeaderWidget({
    Key? key,
    required this.displacement,
    this.valueColor,
    this.backgroundColor,
    required this.headerLayoutNotification,
  }) : super(key: key);

  @override
  MaterialHeaderWidgetState createState() {
    return MaterialHeaderWidgetState();
  }
}

class MaterialHeaderWidgetState extends State<MaterialHeaderWidget> with TickerProviderStateMixin<MaterialHeaderWidget> {
  static final Animatable<double> _oneToZeroTween = Tween<double>(begin: 1.0, end: 0.0);

  RefreshIndicatorMode get _refreshState => widget.headerLayoutNotification.refreshState;

  double get _pulledExtent => widget.headerLayoutNotification.pulledExtent;

  double get _riggerPullDistance => widget.headerLayoutNotification.refreshTriggerPullDistance;

  Duration? get _completeDuration => widget.headerLayoutNotification.completeDuration;

  AxisDirection get _axisDirection => widget.headerLayoutNotification.axisDirection;

  bool get _noMore => widget.headerLayoutNotification.noMore;

  // 动画
  late AnimationController _scaleController;
  late Animation<double> _scaleFactor;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(vsync: this);
    _scaleFactor = _scaleController.drive(_oneToZeroTween);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  bool _refreshFinish = false;

  set refreshFinish(bool finish) {
    if (_refreshFinish != finish) {
      if (finish) {
        Future.delayed(_completeDuration! - const Duration(milliseconds: 300), () {
          if (mounted) {
            _scaleController.animateTo(1.0, duration: _kIndicatorScaleDuration);
          }
        });
        Future.delayed(_completeDuration!, () {
          if (mounted) {
            _refreshFinish = false;
            _scaleController.animateTo(0.0, duration: const Duration(milliseconds: 10));
          }
        });
      }
      _refreshFinish = finish;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_noMore) return Container();
    // Is it vertical
    bool isVertical = _axisDirection == AxisDirection.down || _axisDirection == AxisDirection.up;
    // Is it reversed
    bool isReverse = _axisDirection == AxisDirection.up || _axisDirection == AxisDirection.left;
    // Calculate progress value
    double indicatorValue = _pulledExtent / _riggerPullDistance;
    indicatorValue = indicatorValue < 1.0 ? indicatorValue : 1.0;
    // Determine whether the refresh is complete
    if (_refreshState == RefreshIndicatorMode.refreshed) {
      refreshFinish = true;
    }
    return SizedBox(
      height: isVertical
          ? _refreshState == RefreshIndicatorMode.inactive
              ? 0.0
              : _pulledExtent
          : double.infinity,
      width: !isVertical
          ? _refreshState == RefreshIndicatorMode.inactive
              ? 0.0
              : _pulledExtent
          : double.infinity,
      child: Stack(
        children: <Widget>[
          Positioned(
            top: isVertical
                ? isReverse
                    ? 0.0
                    : null
                : 0.0,
            bottom: isVertical
                ? !isReverse
                    ? 0.0
                    : null
                : 0.0,
            left: !isVertical
                ? isReverse
                    ? 0.0
                    : null
                : 0.0,
            right: !isVertical
                ? !isReverse
                    ? 0.0
                    : null
                : 0.0,
            child: Container(
              padding: EdgeInsets.only(
                top: isVertical
                    ? isReverse
                        ? 0.0
                        : widget.displacement
                    : 0.0,
                bottom: isVertical
                    ? !isReverse
                        ? 0.0
                        : widget.displacement
                    : 0.0,
                left: !isVertical
                    ? isReverse
                        ? 0.0
                        : widget.displacement
                    : 0.0,
                right: !isVertical
                    ? !isReverse
                        ? 0.0
                        : widget.displacement
                    : 0.0,
              ),
              alignment: isVertical
                  ? isReverse
                      ? Alignment.topCenter
                      : Alignment.bottomCenter
                  : isReverse
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
              child: ScaleTransition(
                scale: _scaleFactor,
                child: RefreshProgressIndicator(
                  value: _refreshState == RefreshIndicatorMode.armed ||
                          _refreshState == RefreshIndicatorMode.refresh ||
                          _refreshState == RefreshIndicatorMode.refreshed ||
                          _refreshState == RefreshIndicatorMode.done
                      ? null
                      : indicatorValue,
                  valueColor: widget.valueColor,
                  backgroundColor: widget.backgroundColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
