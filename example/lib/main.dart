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
                  debugPrint('tap -> $index');
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
                        style: const TextStyle(fontSize: 20),
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
        body: CursorSelectorTheme(
            data: CursorSelectorThemeData(selectedAreaDecoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10)
            )),
            child: CursorSelectorWidget(
            scrollController: scrollController,
            selectedChangedCallback: (t) {
              _controller.add(t);
            },
            child: SingleChildScrollView(
              controller: scrollController,
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _list.map<Widget>(buildBox).toList(),
              ),
            ))),
      ),
    );
  }


}





