import 'dart:async';

import 'package:flutter/material.dart';

class ScrollNotificationInheritedWidget extends InheritedWidget {
  ScrollNotificationInheritedWidget({Key? key, required Widget child}) : super(key: key, child: child);

  final StreamController<ScrollNotification> scrollNotificationController = StreamController<ScrollNotification>.broadcast();

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return false;
  }

  static StreamController<ScrollNotification>? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ScrollNotificationInheritedWidget>()?.scrollNotificationController;
  }
}
