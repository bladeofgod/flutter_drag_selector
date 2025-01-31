import 'dart:async';

import 'package:flutter/material.dart';

import 'cursor_selector_theme.dart';

/// Selector-rect changed callback
typedef SelectZoneChangedCallback = void Function(DragUpdateDetails details, Rect selectZone);

/// Selectable container.
/// see also [SelectableItem]
class CursorSelectorWidget extends StatefulWidget {
  /// This child will be in selected zone.
  /// e.g. [ListView], [GridView]
  /// see also [SelectableItem]
  final Widget child;

  /// It will trigger this callback when cursor start drag.
  /// * the event of this callback has been distinct.
  /// see also [CursorSelectorProvider.selectedStream], and you can directly listen it.
  final ValueChanged<(Key?, bool)>? selectedChangedCallback;

  /// Cursor drag start will trigger this callback.
  final GestureDragStartCallback? dragStartCallback;

  /// Cursor drag end will trigger this callback.
  final GestureDragEndCallback? dragEndCallback;

  /// This callback is triggered when dragging the mouse cursor causes the rect to changed.
  ///
  /// * you can set this callback for listen drag details.
  /// * e.g. scroll [ListView]
  final SelectZoneChangedCallback? dragUpdateCallback;

  /// The child scrollView's controller
  /// * user create select zone by dragging cursor, than scrolling mouse wheel,
  /// * than selector can continue select by this [scrollController].
  final ScrollController scrollController;

  /// Manipulate action about scroll when cursor is dragging.
  /// * if [selectorScrollHandler] is null, the value will be set as [DefaultCursorSelectorScrollHandler]
  final CursorSelectorScrollHandler? selectorScrollHandler;

  const CursorSelectorWidget({
    super.key,
    required this.child,
    required this.scrollController,
    this.selectedChangedCallback,
    this.dragStartCallback,
    this.dragEndCallback,
    this.dragUpdateCallback,
    this.selectorScrollHandler,
  });

  @override
  State<StatefulWidget> createState() {
    return _CursorSelectorWidget();
  }
}

class _CursorSelectorWidget extends State<CursorSelectorWidget> {
  late final CursorSelectorScrollHandler _scrollViewHelper;

  Offset? _start;

  /// Update ui of rect selection area.
  final _panUpdater = ValueNotifier<Offset?>(null);

  /// Selected event records
  /// * <Child-Key, isSelected>
  /// * start drag event will clear this records.
  final _eventRecords = <Key?, bool>{};

  /// Listen the item-selected event and distinct it.
  void _distinctCallback((Key?, bool) event) {
    final key = event.$1;
    final isSelected = event.$2;
    if (_eventRecords.containsKey(key) && _eventRecords[key] == isSelected) return;
    _eventRecords[key] = isSelected;
    widget.selectedChangedCallback?.call(event);
  }

  @override
  void initState() {
    _scrollViewHelper =
        widget.selectorScrollHandler ?? DefaultCursorSelectorScrollHandler(childViewScrollController: widget.scrollController);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CursorSelectorProvider(
      child: LayoutBuilder(
        builder: (ctx, cons) {
          final provider = CursorSelectorProvider.maybeOf(ctx);
          if (widget.selectedChangedCallback != null) {
            provider?.selectedStream.listen(_distinctCallback);
          }
          final ancestor = ctx.findRenderObject();
          return GestureDetector(
            onPanStart: (start) {
              _start = start.localPosition;
              _eventRecords.clear();
              widget.dragStartCallback?.call(start);
            },
            onPanUpdate: (update) {
              _panUpdater.value = update.localPosition;
              Rect selectArea = Rect.fromPoints(_start!, update.localPosition);
              final sc = widget.scrollController;
              final scrollOffset = sc.offset;
              switch (sc.position.axis) {
                case Axis.horizontal:
                  selectArea = Rect.fromLTRB(
                      selectArea.left - scrollOffset, selectArea.top, selectArea.right, selectArea.bottom);
                case Axis.vertical:
                  selectArea = Rect.fromLTRB(
                      selectArea.left, selectArea.top - scrollOffset, selectArea.right, selectArea.bottom);
              }
              provider?.cursorDragZoneChanged(selectArea, ancestor);
              _scrollViewHelper.onPanUpdate(update);
              widget.dragUpdateCallback?.call(update, selectArea);
            },
            onPanEnd: (end) {
              _start = null;
              _panUpdater.value = null;
              _scrollViewHelper.onPanEnd(end);
              widget.dragEndCallback?.call(end);
            },
            child: Stack(
              children: [
                ConstrainedBox(
                  constraints: cons,
                  child: widget.child,
                ),
                ValueListenableBuilder<Offset?>(
                    valueListenable: _panUpdater,
                    builder: (ctx, v, child) {
                      if (v == null || _start == null) return const SizedBox.shrink();
                      return Positioned.fromRect(
                          rect: Rect.fromPoints(_start!, v),
                          child: DecoratedBox(decoration: CursorSelectorTheme.of(context)?.selectedAreaDecoration ?? BoxDecoration(
                            color: Colors.blueAccent.withValues(alpha: .4)
                          )));
                    })
              ],
            ),
          );
        },
      ),
    );
  }
}

/// The child who wanna be selected.
/// * [key] must be set.
class SelectableItem extends StatefulWidget {
  const SelectableItem({required super.key, required this.child});

  /// The child of select-zone.
  ///* e.g. children of [ListView] or [GridView], and so on.
  final Widget child;

  @override
  State<StatefulWidget> createState() {
    return _SelectableItemState();
  }
}

class _SelectableItemState extends State<SelectableItem> with SelectTestBinding {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    CursorSelectorProvider.maybeOf(context)?.removeTester(widget.key);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    CursorSelectorProvider.maybeOf(context)?.registerTester(widget.key, this);
    return widget.child;
  }
}

/// Helps item-widget test if it is in the selection area.
mixin SelectTestBinding<T extends StatefulWidget> on State<T> {
  /// Test the cursor drag zone is overlay this child-widget
  bool selectTest(Rect selectRect, RenderObject? ancestor) {
    final rb = context.findRenderObject();
    if (rb is RenderBox) {
      final paintRect = rb.paintBounds;
      final pos = rb.localToGlobal(Offset.zero, ancestor: ancestor);
      final realRect = paintRect.shift(pos);
      return selectRect.overlaps(realRect);
    }
    return false;
  }
}

class CursorSelectorProvider extends InheritedWidget {
  CursorSelectorProvider({super.key, required super.child});

  static CursorSelectorProvider? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CursorSelectorProvider>();
  }

  /// Cache the children who need test.
  final _selectorTest = <Key?, SelectTestBinding>{};

  final _selectorController = StreamController<(Key?, bool)>.broadcast();

  /// Listen the selectable-item's test result.
  /// (item's-key, isSelected)
  Stream<(Key?, bool)> get selectedStream => _selectorController.stream;

  /// Cursor drag-zone changed
  /// * [rect] cursor's drag zone
  /// * [ancestor] contained all children and drag-zone rect
  void cursorDragZoneChanged(Rect rect, RenderObject? ancestor) {
    for (final item in _selectorTest.entries) {
      final box = item.value;
      final isSelected = box.selectTest(rect, ancestor);
      _selectorController.add((item.key, isSelected));
    }
  }

  /// Register child that who want be test in cursor-drag-zone
  ///[key] is relate of your item
  void registerTester(Key? key, SelectTestBinding target) {
    _selectorTest[key] = target;
  }

  /// Remove the item that no need selected.
  void removeTester(Key? key) {
    _selectorTest.remove(key);
  }

  @override
  bool updateShouldNotify(covariant CursorSelectorProvider oldWidget) {
    return _selectorTest.length != oldWidget._selectorTest.length;
  }
}

/// Responsible for handling the interaction with the child scrollview when the cursor is dragged.
abstract class CursorSelectorScrollHandler {

  /// Child scroll-view's scroll controller.
  final ScrollController childViewScrollController;

  CursorSelectorScrollHandler({required this.childViewScrollController});

  void onPanUpdate(DragUpdateDetails details);

  void onPanEnd(DragEndDetails details);
}

/// Handling the scroll action while cursor dragging out of window(or select zone).
///
/// see also
/// [_AutoScrollBinding]
class DefaultCursorSelectorScrollHandler extends CursorSelectorScrollHandler with _AutoScrollBinding {
  DefaultCursorSelectorScrollHandler({required super.childViewScrollController});

  @override
  void onPanEnd(DragEndDetails details) {
    stopAutoScroll();
  }

  @override
  void onPanUpdate(DragUpdateDetails details) {
    final vd = scrollController.position.viewportDimension;
    final jumpPos = switch (scrollController.position.axis) {
      Axis.horizontal => details.delta.dx,
      Axis.vertical => details.delta.dy,
    };
    final localPos = details.localPosition;
    if (localPos.dy > vd || localPos.dy < 0) {
      startAutoScroll(jumpPos);
    } else {
      stopAutoScroll();
    }
  }

  @override
  ScrollController get scrollController => childViewScrollController;
}

/// Control auto scroll
mixin _AutoScrollBinding {

  bool _autoScrollSignal = false;

  ScrollController get scrollController;

  void _launchAutoScroll(double jumpPos) {
    Future<void> startMove() async {
      if (!_autoScrollSignal) return;
      scrollController.position.pointerScroll(jumpPos);
      await WidgetsBinding.instance.endOfFrame;
      unawaited(startMove());
    }
    startMove();
  }

  void stopAutoScroll() {
    _autoScrollSignal = false;
  }

  /// Start scrolling child-view that related [scrollController].
  /// It will stop then call [stopAutoScroll]
  void startAutoScroll(double jumpPos) {
    if(_autoScrollSignal) return;
    _autoScrollSignal = true;
    _launchAutoScroll(jumpPos);
  }
}