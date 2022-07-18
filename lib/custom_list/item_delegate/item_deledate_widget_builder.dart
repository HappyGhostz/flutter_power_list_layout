import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_power_list_layout/custom_list/item_delegate/item_delegate_widget.dart';

enum ListViewItemPosition { top, middle, bottom }

const int _sectionHeaderIndex = -1;

class ListViewItemBuilder {
  /// listView scrollController
  ///
  /// If you want to use [animateTo] or [jumpTo] ,scrollController must not be null.
  ScrollController scrollController;

  /// ListView scrollDirection
  Axis scrollDirection = Axis.vertical;

  /// ListView context
  BuildContext listViewContext;

  /// All item height cache.
  final Map<String, Size> _itemsSizeCache = <String, Size>{};

  int itemCount;

  ListViewItemBuilder({
    required this.listViewContext,
    required this.scrollController,
    required this.scrollDirection,
    required this.itemCount,
  }) : super();

  Widget itemContainer(BuildContext context, Widget item, int index) {
    return _buildWidgetContainer(
      index.toString(),
      item,
    );
  }

  int convertIndexPathToIndex(int section, int index) => 0;

  /// [scrollController] must not be null.
  Future<void> jumpTo(int index, {ListViewItemPosition position = ListViewItemPosition.top}) async {
    await _jumpTo(index, position: position, isNeedAnimation: false);
  }

  /// Animates the position from its current value to the given index.
  ///
  /// [scrollController] must not be null.
  Future<void> animateTo(int index,
      {required Duration duration, required Curve curve, ListViewItemPosition position = ListViewItemPosition.top}) async {
    var startOffset = scrollController.offset;
    bool isInvisibleNeedToScroll = await _jumpTo(index, position: position, isNeedAnimation: true);

    ///For isInvisibleNeedToScroll, because start open list, the _itemsSizeCache only has 7 child, and
    ///when we need move to the 15 index, if we do not use isInvisibleNeedToScroll to check, and in the
    ///_jumpTo method about scrollController.position.moveTo do not use the duration to call, will instantly jump to item 15
    ///And call await scrollController.position.moveTo(startOffset) and animateTo, will move to the 1 item, and start
    ///animation to the 15 item, This will be another flash. so I use the isInvisibleNeedToScroll to avoid call moveTo(startOffset)
    ///and in the  _jumpTo method, I add duration for move method.
    if (isInvisibleNeedToScroll == false) {
      var endOffset = scrollController.offset;
      await scrollController.position.moveTo(startOffset);
      return scrollController.animateTo(endOffset, duration: duration, curve: curve);
    }
  }

  Future<bool> _jumpTo(int index, {ListViewItemPosition position = ListViewItemPosition.top, bool isNeedAnimation = true}) async {
    assert(scrollController.hasClients == true);
    assert(listViewContext.findRenderObject()?.paintBounds != null, "The listView must already be laid out.");

    /// Current max visible item position
    int maxIndex = _sectionHeaderIndex;

    double itemsTotalHeight = 0.0;
    double targetItemHeight = 0.0;
    double targetItemTop = 0.0;

    var viewPortHeight = _getHeight(listViewContext.findRenderObject()?.paintBounds.size);

    _itemsSizeCache.forEach((key, size) {
      int cacheIndex = int.parse(key);
      var itemHeight = _getHeight(size);

      /// Find max index
      if (cacheIndex > maxIndex) {
        maxIndex = cacheIndex;
        itemsTotalHeight += itemHeight;
      }

      if (cacheIndex < index) {
        targetItemTop += itemHeight;
      }

      if (index == cacheIndex) {
        targetItemHeight = itemHeight;
      }
    });

    /// Target item is visible,we can get it's size info.
    if (index < maxIndex) {
      scrollController.jumpTo(
        _calculateOffset(targetItemTop, targetItemHeight, position: position, viewPortHeight: viewPortHeight),
      );
      return Future.value(false);
    } else {
      /// Target item is invisible,It hasn't been laid out yet.
      var invisibleKeys = [];

      var targetKey = _cacheKey(index: index);

      int beginInvisibleIndex = maxIndex + 1;
      for (int i = beginInvisibleIndex; i < itemCount; i++) {
        invisibleKeys.add(_cacheKey(index: i));
      }

      int currentCacheIndex = 0;
      double tryPixel = 1;
      double tryOffset = itemsTotalHeight - viewPortHeight;
      bool isTargetIndex = false;
      int targetKeyIndex = invisibleKeys.indexOf(targetKey);

      /// Each time we ask the scrollController to try to scroll down tryPixel to start the listView's preload mechanism,
      /// we will get the latest item layout result after the item layout is finished,
      /// and accumulate itemsHeight until the boundary is triggered and the loop is finished.
      while (true) {
        tryOffset += tryPixel;

        if (isTargetIndex) break;
        if (currentCacheIndex >= invisibleKeys.length) break;
        if (tryOffset >= scrollController.position.maxScrollExtent) break;

        /// Wait scrollController move finished
        /// await scrollController.position.moveTo(tryOffset);
        /// Cooperate with isInvisibleNeedToScroll
        if (isNeedAnimation) {
          await scrollController.position.moveTo(tryOffset, duration: const Duration(seconds: 1));
        } else {
          await scrollController.position.moveTo(tryOffset);
        }

        /// Wait items layout finished
        await SchedulerBinding.instance?.endOfFrame;

        var nextHeights = 0.0;

        /// ListView maybe layout many items
        var _currentCacheIndex = currentCacheIndex;
        for (int i = currentCacheIndex; i < invisibleKeys.length; i++) {
          var nextCacheKey = invisibleKeys[i];

          if (int.parse(nextCacheKey) >= _itemsSizeCache.length) {
            /// Wait scrollController move finished
            /// await scrollController.position.moveTo(itemsTotalHeight);
            /// Cooperate with isInvisibleNeedToScroll
            if (isNeedAnimation) {
              await scrollController.position.moveTo(itemsTotalHeight, duration: const Duration(seconds: 1));
            } else {
              await scrollController.position.moveTo(itemsTotalHeight);
            }

            /// Wait items layout finished
            await SchedulerBinding.instance?.endOfFrame;
          }

          var nextHeight = _getHeight(_itemsSizeCache[nextCacheKey]);

          if (i == targetKeyIndex) {
            isTargetIndex = true;
            targetItemHeight = nextHeight;
            break;
          } else {
            nextHeights += nextHeight;
            _currentCacheIndex = i;
          }
        }
        currentCacheIndex = _currentCacheIndex;

        itemsTotalHeight += nextHeights;
        currentCacheIndex++;
        tryOffset = itemsTotalHeight - viewPortHeight;
      }

      Future<void> _scrollToTargetPosition(bool isNeedAnimation) async {
        /// Cooperate with isInvisibleNeedToScroll
        if (isNeedAnimation) {
          return scrollController.position.moveTo(
              _calculateOffset(itemsTotalHeight, targetItemHeight, position: position, viewPortHeight: viewPortHeight),
              duration: const Duration(seconds: 1));
        }
        return scrollController.position.moveTo(
          _calculateOffset(itemsTotalHeight, targetItemHeight, position: position, viewPortHeight: viewPortHeight),
        );
      }

      await _scrollToTargetPosition(isNeedAnimation);
      await SchedulerBinding.instance?.endOfFrame;
      return Future.value(true);
    }
  }

  double _calculateOffset(double top, double itemHeight,
      {ListViewItemPosition position = ListViewItemPosition.top, double viewPortHeight = 0.0}) {
    double offset = 0.0;
    switch (position) {
      case ListViewItemPosition.top:
        offset = top - itemHeight;
        break;
      case ListViewItemPosition.middle:
        offset = top - itemHeight * 0.5;
        break;
      case ListViewItemPosition.bottom:
        offset = top;
        break;
    }
    if (offset > scrollController.position.maxScrollExtent) {
      return _min(offset, _maxScrollExtent() - viewPortHeight);
    } else {
      return offset;
    }
  }

  /// Instead of [scrollController.position.maxScrollExtent]
  double _maxScrollExtent() {
    double height = 0.0;
    for (var v in _itemsSizeCache.values) {
      height += _getHeight(v);
    }
    return height;
  }

  _min(double a, double b) => a < b ? a : b;

  double _getHeight(Size? size) => (scrollDirection == Axis.vertical ? size?.height : size?.width) ?? 0;

  Widget _buildWidgetContainer(String cacheKey, Widget widget) {
    return ScrollerViewItemContainer(
      cacheKey: cacheKey,
      child: widget,
      listViewContext: listViewContext,
      itemHeightCache: _itemsSizeCache,
    );
  }

  String _cacheKey({int index = 0}) => index.toString();

/**
 * Expose item data, track data. one of the options
 * https://github.com/Vadaski/flutter_exposure/blob/main/lib/list/exposure_widget.dart
 * void subscribeScrollNotification() {
    final StreamController<ScrollNotification> publisher =
    ScrollNotificationInheritedWidget.of(context);
    publisher.stream.listen((scrollNotification) {
    checkExpose(
    scrollNotification.metrics.pixels, scrollNotification.metrics.axis);
    });
    }
 *  checkExpose(...){
 *    like onExpose.call();
 *  }
 */
}
