import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_power_list_layout/custom_list/footer/footer.dart';
import 'package:flutter_power_list_layout/custom_list/footer/footer_layout_notification.dart';
import 'package:flutter_power_list_layout/custom_list/load/power_load_layout_widget.dart';

class BallPulseFooter extends Footer {
  final Key? key;

  final Color? color;

  final Color? backgroundColor;

  final FooterLayoutNotification linkNotifier = FooterLayoutNotification();

  BallPulseFooter({
    this.key,
    this.color = Colors.blue,
    this.backgroundColor = Colors.transparent,
    bool enableHapticFeedback = true,
    bool enableInfiniteLoad = false,
    bool overScroll = false,
  }) : super(
          extent: 70.0,
          triggerDistance: 70.0,
          float: false,
          enableHapticFeedback: enableHapticFeedback,
          enableInfiniteLoad: enableInfiniteLoad,
          overScroll: overScroll,
        );

  @override
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
      bool noMore) {
    // 不能为水平方向
    assert(axisDirection == AxisDirection.down || axisDirection == AxisDirection.up, 'Widget cannot be horizontal');
    linkNotifier.contentBuilder(context, loadState, pulledExtent, loadTriggerPullDistance, loadIndicatorExtent, axisDirection, float,
        completeDuration, enableInfiniteLoad, success, noMore);
    return BallPulseFooterWidget(
      key: key,
      color: color,
      backgroundColor: backgroundColor,
      linkNotifier: linkNotifier,
    );
  }
}

class BallPulseFooterWidget extends StatefulWidget {
  final Color? color;

  final Color? backgroundColor;

  final FooterLayoutNotification linkNotifier;

  const BallPulseFooterWidget({
    Key? key,
    this.color,
    this.backgroundColor,
    required this.linkNotifier,
  }) : super(key: key);

  @override
  BallPulseFooterWidgetState createState() {
    return BallPulseFooterWidgetState();
  }
}

class BallPulseFooterWidgetState extends State<BallPulseFooterWidget> {
  LoadIndicatorMode get _loadState => widget.linkNotifier.loadState;

  double get _indicatorExtent => widget.linkNotifier.loadIndicatorExtent;

  bool get _noMore => widget.linkNotifier.noMore;

  double _ballSize1 = 0.0, _ballSize2 = 0.0, _ballSize3 = 0.0;

  int animationPhase = 1;

  final Duration _ballSizeDuration = const Duration(milliseconds: 200);

  bool _isAnimated = false;

  @override
  void initState() {
    super.initState();
  }

  void _loopAnimated() {
    Future.delayed(_ballSizeDuration, () {
      if (!mounted) return;
      if (_isAnimated) {
        setState(() {
          if (animationPhase == 1) {
            _ballSize1 = 13.0;
            _ballSize2 = 6.0;
            _ballSize3 = 13.0;
          } else if (animationPhase == 2) {
            _ballSize1 = 20.0;
            _ballSize2 = 13.0;
            _ballSize3 = 6.0;
          } else if (animationPhase == 3) {
            _ballSize1 = 13.0;
            _ballSize2 = 20.0;
            _ballSize3 = 13.0;
          } else {
            _ballSize1 = 6.0;
            _ballSize2 = 13.0;
            _ballSize3 = 20.0;
          }
        });
        animationPhase++;
        animationPhase = animationPhase >= 5 ? 1 : animationPhase;
        _loopAnimated();
      } else {
        setState(() {
          _ballSize1 = 0.0;
          _ballSize2 = 0.0;
          _ballSize3 = 0.0;
        });
        animationPhase = 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_noMore) return Container();
    if (_loadState == LoadIndicatorMode.done || _loadState == LoadIndicatorMode.inactive) {
      _isAnimated = false;
    } else if (!_isAnimated) {
      _isAnimated = true;
      setState(() {
        _ballSize1 = 6.0;
        _ballSize2 = 13.0;
        _ballSize3 = 20.0;
      });
      _loopAnimated();
    }
    return Stack(
      children: <Widget>[
        Positioned(
          top: 0.0,
          bottom: 0.0,
          left: 0.0,
          right: 0.0,
          child: Container(
            alignment: Alignment.center,
            height: _indicatorExtent,
            color: widget.backgroundColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  width: 20.0,
                  height: 20.0,
                  child: Center(
                    child: ClipOval(
                      child: AnimatedContainer(
                        color: widget.color,
                        height: _ballSize1,
                        width: _ballSize1,
                        duration: _ballSizeDuration,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 5.0,
                ),
                SizedBox(
                  width: 20.0,
                  height: 20.0,
                  child: Center(
                    child: ClipOval(
                      child: AnimatedContainer(
                        color: widget.color,
                        height: _ballSize2,
                        width: _ballSize2,
                        duration: _ballSizeDuration,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 5.0,
                ),
                SizedBox(
                  width: 20.0,
                  height: 20.0,
                  child: Center(
                    child: ClipOval(
                      child: AnimatedContainer(
                        color: widget.color,
                        height: _ballSize3,
                        width: _ballSize3,
                        duration: _ballSizeDuration,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
