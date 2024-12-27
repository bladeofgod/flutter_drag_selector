import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_drag_selector/flutter_drag_selector.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _list = List.generate(50, (i) => i);

  final _controller = StreamController<(Key?, bool)>.broadcast();

  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // scrollController.addListener(() {
    //   final pos = scrollController.position;
    //   debugPrint('${pos.axis}------- ${pos.extentBefore} ===== ${pos.pixels}');
    // });
  }

  @override
  void dispose() {
    _controller.close();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget buildBox(int index) {
      final id = ValueKey<int>(index);
      return StreamBuilder<(Key?, bool)>(
          stream: _controller.stream.where((e) => e.$1 == id),
          builder: (ctx, snapshot) {
            return SelectableItem(
              key: id,
              child: GestureDetector(
                onTap: () {
                  debugPrint('tap---- $index');
                },
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(color: index % 2 == 0 ? Colors.yellow : Colors.lightBlueAccent),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$index',
                        style: TextStyle(fontSize: 20),
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      Icon(
                        (snapshot.data?.$2 ?? false) ? Icons.check_box : Icons.check_box_outline_blank,
                        size: 40,
                        color: Colors.red,
                      )
                    ],
                  ),
                ),
              ),
            );
          });
    }

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: CursorSelectorWidget(
            scrollController: scrollController,
            dragStartCallback: (start) {
              //_dragRecords.clear();
            },
            dragUpdateCallback: (update, selectZone) {
              final vd = scrollController.position.viewportDimension;
              final scrollPos = scrollController.offset;
              //debugPrint('$selectZone---- ${update.delta}  ==========${update.sourceTimeStamp?.inMicroseconds} ');
              final jumpPos = switch(scrollController.position.axis) {
                Axis.horizontal => update.delta.dx,
                Axis.vertical => update.delta.dy,
              };
              final localPos = update.localPosition;
              if(localPos.dy > vd || localPos.dy < 0) {
                scrollController.position.pointerScroll(jumpPos);
              }
            },
            selectedChangedCallback: (t) {
              //debugPrint('${t.$1} ------ ${t.$2}');
              _controller.add(t);
            },
            child: SingleChildScrollView(
              controller: scrollController,
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _list.map<Widget>(buildBox).toList(),
              ),
            )),
      ),
    );
  }
}

///Selector-rect changed callback
typedef SelectZoneChangedCallback = void Function(DragUpdateDetails details, Rect selectZone);

///Selectable container.
///see also [SelectableItem]
class CursorSelectorWidget extends StatefulWidget {
  ///This child will be in selected zone.
  /// e.g. [ListView], [GridView]
  /// see also [SelectableItem]
  final Widget child;

  ///It will trigger this callback when cursor start drag.
  /// * the event of this callback has been distinct.
  /// see also [CursorSelectorProvider.selectedStream], and you can directly listen it.
  final ValueChanged<(Key?, bool)>? selectedChangedCallback;

  ///Cursor drag start will trigger this callback.
  final GestureDragStartCallback? dragStartCallback;

  ///Cursor drag end will trigger this callback.
  final GestureDragEndCallback? dragEndCallback;

  ///This callback is triggered when dragging the mouse cursor causes
  ///the rect to changed.
  /// * you can set this callback for listen drag details.
  /// * e.g. scroll [ListView]
  final SelectZoneChangedCallback? dragUpdateCallback;

  final ScrollController scrollController;

  const CursorSelectorWidget({
    super.key,
    required this.child,
    required this.scrollController,
    this.selectedChangedCallback,
    this.dragStartCallback,
    this.dragEndCallback,
    this.dragUpdateCallback,
  });

  @override
  State<StatefulWidget> createState() {
    return _CursorSelectorWidget();
  }
}

class _CursorSelectorWidget extends State<CursorSelectorWidget> {

  Offset? _start;

  ///Update ui of rect selection area.
  final _panUpdater = ValueNotifier<Offset?>(null);

  final _eventRecords = <Key?, bool>{};

  void _distinctCallback((Key?, bool) event) {
    final key = event.$1;
    final isSelected = event.$2;
    if (_eventRecords.containsKey(key) && _eventRecords[key] == isSelected) return;
    _eventRecords[key] = isSelected;
    widget.selectedChangedCallback?.call(event);
  }

  @override
  void initState() {
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
              widget.dragUpdateCallback?.call(update, selectArea);
            },
            onPanEnd: (end) {
              _start = null;
              _panUpdater.value = null;
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
                          child: ColoredBox(color: Colors.lightBlueAccent.withOpacity(0.4)));
                    })
              ],
            ),
          );
        },
      ),
    );
  }
}

///The child who wanna be selected.
/// * [key] must be set.
class SelectableItem extends StatefulWidget {
  const SelectableItem({required super.key, required this.child});

  ///the child of select-zone.
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

mixin SelectTestBinding<T extends StatefulWidget> on State<T> {
  ///Test the cursor drag zone is overlay this child-widget
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

  ///cache the children who need test.
  final _selectorTest = <Key?, SelectTestBinding>{};

  final _selectorController = StreamController<(Key?, bool)>.broadcast();

  ///listen the selectable-item's test result.
  ///(item's-key, isSelected)
  Stream<(Key?, bool)> get selectedStream => _selectorController.stream;

  ///cursor drag-zone changed
  /// * [rect] cursor's drag zone
  /// * [ancestor] contained all children and drag-zone rect
  void cursorDragZoneChanged(Rect rect, RenderObject? ancestor) {
    for (final item in _selectorTest.entries) {
      final box = item.value;
      final isSelected = box.selectTest(rect, ancestor);
      _selectorController.add((item.key, isSelected));
    }
  }

  ///register child that who want be test in cursor-drag-zone
  ///[key] is relate of your item
  void registerTester(Key? key, SelectTestBinding target) {
    _selectorTest[key] = target;
  }

  ///remove the item that no need selected.
  void removeTester(Key? key) {
    _selectorTest.remove(key);
  }

  @override
  bool updateShouldNotify(covariant CursorSelectorProvider oldWidget) {
    return _selectorTest.length != oldWidget._selectorTest.length;
  }
}
