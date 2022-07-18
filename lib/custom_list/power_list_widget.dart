import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_power_list_layout/custom_list/custom_refresh_load_control/power_list_control.dart';
import 'package:flutter_power_list_layout/custom_list/custom_refresh_load_control/task_state.dart';
import 'package:flutter_power_list_layout/custom_list/item_delegate/item_deledate_widget_builder.dart';
import 'package:flutter_power_list_layout/custom_list/load/power_load_layout_widget.dart';
import 'package:flutter_power_list_layout/custom_list/refresh/power_refresh_layout_widget.dart';
import 'package:flutter_power_list_layout/custom_list/scroll/scroll_notification_listener.dart';

import 'behavior/scroll_behavior.dart';
import 'footer/footer.dart';
import 'header/header.dart';
import 'physics/scroll_physics.dart';

typedef PowerListItemBuilder = Widget Function(BuildContext context, int index);

class PowerListWidget extends StatefulWidget {
  /// controller
  final PowerListController? controller;

  /// Refresh callback (null means no refresh is enabled)
  final OnRefreshCallback? onRefresh;

  /// Loading callback (null means no loading is enabled)
  final OnLoadCallback? onLoad;

  /// Whether to enable the control to end the refresh
  final bool enableControlFinishRefresh;

  /// Whether to enable control to end loading
  final bool enableControlFinishLoad;

  /// Task independent (refresh and load state independent)
  final bool taskIndependence;

  /// Header
  final Header? header;
  final int headerIndex;

  /// Footer
  final Footer? footer;

  final PowerListItemBuilder itemBuilder;

  /// Top rebound (Header's overScroll property takes precedence, and takes effect when both onRefresh and header are null)
  final bool topBouncing;

  /// Bottom bounce (Footer's overScroll property takes precedence, and takes effect when both onLoad and footer are null)
  final bool bottomBouncing;

  /// CustomListView Key
  final Key? listKey;

  /// scrolling behavior
  final ScrollBehavior? behavior;

  /// list direction
  final Axis scrollDirection;

  /// reverse
  final bool reverse;
  final ScrollController? scrollController;
  final bool? primary;
  final bool shrinkWrap;
  final Key? center;
  final double anchor;
  final double? cacheExtent;
  final int? semanticChildCount;
  final DragStartBehavior dragStartBehavior;

  /// Exceeded distance when triggered
  static double callOverExtent = 30.0;

  final int itemCount;

  const PowerListWidget({
    Key? key,
    this.controller,
    required this.itemBuilder,
    required this.itemCount,
    this.onRefresh,
    this.onLoad,
    this.enableControlFinishRefresh = false,
    this.enableControlFinishLoad = false,
    this.taskIndependence = false,
    this.scrollController,
    this.header,
    this.footer,
    this.headerIndex = 0,
    this.topBouncing = true,
    this.bottomBouncing = true,
    this.behavior = const EmptyOverScrollScrollBehavior(),
  })  : scrollDirection = Axis.vertical,
        reverse = false,
        primary = null,
        shrinkWrap = false,
        center = null,
        anchor = 0.0,
        cacheExtent = null,
        semanticChildCount = null,
        dragStartBehavior = DragStartBehavior.start,
        listKey = null,
        super(key: key);

  @override
  PowerListWidgetState createState() {
    return PowerListWidgetState();
  }
}

class PowerListWidgetState extends State<PowerListWidget> {
  // Physics
  late PowerListRefreshPhysics _physics;

  // Header
  Header? get _header => widget.header;

  // Footer
  Footer? get _footer => widget.footer;

  // ScrollController
  late ScrollController _scrollerController;

  // scroll focus status
  late ValueNotifier<bool> _focusNotifier;

  // task status
  late ValueNotifier<TaskState> _taskNotifier;

  // trigger refresh state
  late ValueNotifier<bool> _callRefreshNotifier;

  // trigger loading state
  late ValueNotifier<bool> _callLoadNotifier;

  // Rebound settings
  late ValueNotifier<BouncingSettings> _bouncingNotifier;

  // Extra length when the list is not full
  late ValueNotifier<double> _extraExtentNotifier;

  ListViewItemBuilder? listViewItemBuilder;

  // 初始化
  @override
  void initState() {
    _scrollerController = widget.scrollController ?? ScrollController();
    super.initState();
    _focusNotifier = ValueNotifier<bool>(false);
    _taskNotifier = ValueNotifier(TaskState());
    _callRefreshNotifier = ValueNotifier<bool>(false);
    _callLoadNotifier = ValueNotifier<bool>(false);
    _bouncingNotifier = ValueNotifier<BouncingSettings>(BouncingSettings());
    _extraExtentNotifier = ValueNotifier<double>(0.0);
    _bindController();
    _createPhysics();
  }

  @override
  void didUpdateWidget(PowerListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _bindController();
    }
    if (oldWidget.onRefresh != widget.onRefresh ||
        oldWidget.onLoad != widget.onLoad ||
        oldWidget.topBouncing != widget.topBouncing ||
        oldWidget.bottomBouncing != widget.bottomBouncing ||
        oldWidget.header != widget.header ||
        oldWidget.footer != widget.footer) {
      _createPhysics();
    }
  }

  @override
  void dispose() {
    _focusNotifier.dispose();
    _taskNotifier.dispose();
    _callRefreshNotifier.dispose();
    _callLoadNotifier.dispose();
    _bouncingNotifier.dispose();
    _extraExtentNotifier.dispose();
    widget.controller?.dispose();
    super.dispose();
  }

  // Bind Controller
  void _bindController() {
    // bind controller
    widget.controller?.bindPowerListWidgetState(this);

    listViewItemBuilder = ListViewItemBuilder(
        listViewContext: context,
        scrollController: _scrollerController,
        scrollDirection: widget.scrollDirection,
        itemCount: widget.itemCount);
    widget.controller?.bindPowerListItemBuilder(listViewItemBuilder);
  }

  // Generate rolling physical form
  void _createPhysics() {
    _bouncingNotifier.value = BouncingSettings(
      top: widget.onRefresh == null
          ? widget.header == null
              ? widget.topBouncing
              : widget.header!.overScroll || !widget.header!.enableInfiniteRefresh
          : _header?.overScroll == true || _header?.enableInfiniteRefresh == false,
      bottom: widget.onLoad == null
          ? widget.footer == null
              ? widget.bottomBouncing
              : widget.footer!.overScroll || !widget.footer!.enableInfiniteLoad
          : _footer?.overScroll == true || _footer?.enableInfiniteLoad == false,
    );
    _physics = PowerListRefreshPhysics(
      taskNotifier: _taskNotifier,
      bouncingNotifier: _bouncingNotifier,
      extraExtentNotifier: _extraExtentNotifier,
    );
  }

  void callRefresh({Duration duration = const Duration(milliseconds: 400)}) {
    assert(duration.inMilliseconds > 100, "duration must be greater than 100 milliseconds");
    if (_scrollerController.hasClients == false || _taskNotifier.value.refreshing) return;
    _callRefreshNotifier.value = true;
    _scrollerController
        .animateTo(-0.0001, duration: Duration(milliseconds: duration.inMilliseconds - 100), curve: Curves.linear)
        .whenComplete(() {
      _scrollerController.animateTo(-(_header?.triggerDistance ?? 0 + PowerListWidget.callOverExtent),
          duration: const Duration(milliseconds: 100), curve: Curves.linear);
    });
  }

  void callLoad({Duration duration = const Duration(milliseconds: 400)}) {
    assert(duration.inMilliseconds > 100, "duration must be greater than 100 milliseconds");
    if (_scrollerController.hasClients == false || _taskNotifier.value.loading) return;
    // ignore: invalid_use_of_protected_member
    ScrollPosition position = _scrollerController.positions.length > 1
        // ignore: invalid_use_of_protected_member
        ? _scrollerController.positions.elementAt(0)
        : _scrollerController.position;
    _callLoadNotifier.value = true;
    _scrollerController
        .animateTo(position.maxScrollExtent, duration: Duration(milliseconds: duration.inMilliseconds - 100), curve: Curves.linear)
        .whenComplete(() {
      _scrollerController.animateTo(position.maxScrollExtent + (_footer?.triggerDistance ?? 70) + PowerListWidget.callOverExtent,
          duration: const Duration(milliseconds: 100), curve: Curves.linear);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScrollNotificationListener(
      onNotification: (notification) {
        return false;
      },
      onFocus: (focus) {
        _focusNotifier.value = focus;
      },
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context),
        child: CustomScrollView(
          physics: _physics,
          key: widget.listKey,
          scrollDirection: widget.scrollDirection,
          reverse: widget.reverse,
          controller: _scrollerController,
          primary: widget.primary,
          shrinkWrap: widget.shrinkWrap,
          center: widget.center,
          anchor: widget.anchor,
          cacheExtent: widget.cacheExtent,
          semanticChildCount: widget.semanticChildCount,
          dragStartBehavior: widget.dragStartBehavior,
          slivers: [
            _header != null
                ? _header!.builder(context, _focusNotifier, _taskNotifier, _callRefreshNotifier, widget.onRefresh, widget.taskIndependence,
                    widget.enableControlFinishRefresh, widget.controller)
                : const SizedBox(),
            SliverList(
                delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (listViewItemBuilder == null) {
                  return widget.itemBuilder(context, index);
                }
                return listViewItemBuilder?.itemContainer(context, widget.itemBuilder(context, index), index);
              },
              childCount: widget.itemCount,
            )),
            _footer != null
                ? _footer!.builder(context, _focusNotifier, _taskNotifier, _callLoadNotifier, _extraExtentNotifier, widget.onLoad,
                    widget.taskIndependence, widget.enableControlFinishRefresh, widget.controller)
                : const SizedBox(),
          ],
        ),
      ),
    );
  }
}
