import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ScrollerViewItemContainer extends StatefulWidget {
  final String cacheKey;
  final BuildContext listViewContext;
  final Widget child;
  final Map<String, Size> itemHeightCache;

  const ScrollerViewItemContainer({
    Key? key,
    required this.listViewContext,
    required this.child,
    required this.cacheKey,
    required this.itemHeightCache,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ScrollerViewItemContainerState();
}

class _ScrollerViewItemContainerState extends State<ScrollerViewItemContainer> {
  @override
  Widget build(BuildContext context) {
    return NotificationListener<LayoutChangedNotification>(
      onNotification: (notification) {
        _saveHeightToCache();
        return false;
      },
      child: InitialSizeChangedLayoutNotifier(
        child: widget.child,
      ),
    );
  }

  _saveHeightToCache() {
    if (!mounted) return;
    var size = context.findRenderObject()?.paintBounds.size;
    if (size != null) {
      widget.itemHeightCache[widget.cacheKey] = size;
    }
  }
}

/// Added [SizeChangedLayoutNotifier] initial notification.
class InitialSizeChangedLayoutNotifier extends SingleChildRenderObjectWidget {
  const InitialSizeChangedLayoutNotifier({
    Key? key,
    Widget? child,
  }) : super(key: key, child: child);

  @override
  _InitialRenderSizeChangedWithCallback createRenderObject(BuildContext context) {
    return _InitialRenderSizeChangedWithCallback(onLayoutChangedCallback: () {
      SizeChangedLayoutNotification().dispatch(context);
    });
  }
}

class _InitialRenderSizeChangedWithCallback extends RenderProxyBox {
  _InitialRenderSizeChangedWithCallback({RenderBox? child, required this.onLayoutChangedCallback}) : super(child);

  final VoidCallback onLayoutChangedCallback;

  Size? _oldSize;

  @override
  void performLayout() {
    super.performLayout();
    // Send the initial notification, or this will be SizeObserver all
    // over again!
    if (size != _oldSize) onLayoutChangedCallback();
    _oldSize = size;
  }
}
