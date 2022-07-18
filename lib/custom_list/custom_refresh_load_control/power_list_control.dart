import 'package:flutter/material.dart';
import 'package:flutter_power_list_layout/custom_list/item_delegate/item_deledate_widget_builder.dart';
import 'package:flutter_power_list_layout/custom_list/load/power_load_layout_widget.dart';
import 'package:flutter_power_list_layout/custom_list/power_list_widget.dart';
import 'package:flutter_power_list_layout/custom_list/refresh/power_refresh_layout_widget.dart';

abstract class PowerListAbstractController {
  void callRefresh({Duration duration = const Duration(milliseconds: 300)});

  void callLoad({Duration duration = const Duration(milliseconds: 300)});

  void finishRefresh({
    bool success = true,
    bool noMore = false,
  });

  void finishLoad({
    bool success = true,
    bool noMore = false,
  });

  void resetRefreshState();

  void resetLoadState();

  void bindPowerListWidgetState(PowerListWidgetState state);

  void bindPowerListItemBuilder(ListViewItemBuilder listViewItemBuilder);

  Future<void> jumpTo(int index, {ListViewItemPosition position = ListViewItemPosition.top});

  Future<void> animateTo(int index, {Duration duration, Curve curve, ListViewItemPosition position = ListViewItemPosition.top});

  void dispose();
}

/// control Power list
class PowerListController extends PowerListAbstractController {
  /// trigger refresh
  @override
  void callRefresh({Duration duration = const Duration(milliseconds: 300)}) {
    _powerListWidgetState?.callRefresh(duration: duration);
  }

  /// trigger loading
  @override
  void callLoad({Duration duration = const Duration(milliseconds: 300)}) {
    _powerListWidgetState?.callLoad(duration: duration);
  }

  /// complete refresh
  FinishRefresh? finishRefreshCallBack;

  @override
  void finishRefresh({
    bool success = true,
    bool noMore = false,
  }) {
    if (finishRefreshCallBack != null) {
      finishRefreshCallBack!(success: success, noMore: noMore);
    }
  }

  /// finished loading
  FinishLoad? finishLoadCallBack;

  @override
  void finishLoad({
    bool success = true,
    bool noMore = false,
  }) {
    if (finishLoadCallBack != null) {
      finishLoadCallBack!(success: success, noMore: noMore);
    }
  }

  /// Restore refresh state (used after no more)
  VoidCallback? resetRefreshStateCallBack;

  @override
  void resetRefreshState() {
    if (resetRefreshStateCallBack != null) {
      resetRefreshStateCallBack!();
    }
  }

  /// restore loading state (used after no more)
  VoidCallback? resetLoadStateCallBack;

  @override
  void resetLoadState() {
    if (resetLoadStateCallBack != null) {
      resetLoadStateCallBack!();
    }
  }

  // state
  PowerListWidgetState? _powerListWidgetState;

  // binding state
  @override
  void bindPowerListWidgetState(PowerListWidgetState state) {
    _powerListWidgetState = state;
  }

  ListViewItemBuilder? _listViewItemBuilder;

  // binding state
  @override
  void bindPowerListItemBuilder(ListViewItemBuilder? listViewItemBuilder) {
    _listViewItemBuilder = listViewItemBuilder;
  }

  /// [scrollController] must not be null.
  @override
  Future<void> jumpTo(int index, {ListViewItemPosition position = ListViewItemPosition.top}) async {
    return _listViewItemBuilder?.jumpTo(index, position: position);
  }

  /// Animates the position from its current value to the given index.
  ///
  /// [scrollController] must not be null.
  @override
  Future<void> animateTo(int index,
      {Duration duration = const Duration(microseconds: 500),
      Curve curve = Curves.linear,
      ListViewItemPosition position = ListViewItemPosition.top}) async {
    _listViewItemBuilder?.animateTo(index, duration: duration, curve: curve);
  }

  @override
  void dispose() {
    _powerListWidgetState = null;
    finishRefreshCallBack = null;
    finishLoadCallBack = null;
    resetLoadStateCallBack = null;
    resetRefreshStateCallBack = null;
    _listViewItemBuilder = null;
  }
}
