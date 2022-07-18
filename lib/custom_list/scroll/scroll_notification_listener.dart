import 'package:flutter/material.dart';
import 'package:flutter_power_list_layout/custom_list/scroll/scroll_notification_inherited_widget.dart';

/// Scroll focus callback
/// focus is whether there is focus (the finger is pressed and released)
typedef ScrollFocusCallback = void Function(bool focus);

/// Scroll event listener
class ScrollNotificationListener extends StatefulWidget {
  const ScrollNotificationListener({
    Key? key,
    required this.child,
    this.onNotification,
    this.onFocus,
  }) : super(key: key);

  final Widget child;

  // notification callback
  final NotificationListenerCallback<ScrollNotification>? onNotification;

  // scroll focus callback
  final ScrollFocusCallback? onFocus;

  @override
  ScrollNotificationListenerState createState() {
    return ScrollNotificationListenerState();
  }
}

class ScrollNotificationListenerState extends State<ScrollNotificationListener> {
  // focus status
  bool _focusState = false;

  set _focus(bool focus) {
    _focusState = focus;
    if (widget.onFocus != null) widget.onFocus!(_focusState);
  }

  // Handling scrolling notifications
  void _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      if (notification.dragDetails != null) {
        _focus = true;
      }
    } else if (notification is ScrollUpdateNotification) {
      if (_focusState && notification.dragDetails == null) _focus = false;
    } else if (notification is ScrollEndNotification) {
      if (_focusState) _focus = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScrollNotificationInheritedWidget(
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          //to do add(notification) for Expose item data
          //Can check https://github.com/Vadaski/flutter_exposure/blob/main/lib/list/exposure_widget.dart
          ScrollNotificationInheritedWidget.of(context)?.add(notification);
          _handleScrollNotification(notification);
          return widget.onNotification == null ? true : widget.onNotification!(notification);
        },
        child: widget.child,
      ),
    );
  }
}
