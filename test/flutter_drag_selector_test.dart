import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_drag_selector/flutter_drag_selector.dart';
import 'package:flutter_drag_selector/flutter_drag_selector_platform_interface.dart';
import 'package:flutter_drag_selector/flutter_drag_selector_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterDragSelectorPlatform
    with MockPlatformInterfaceMixin
    implements FlutterDragSelectorPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterDragSelectorPlatform initialPlatform = FlutterDragSelectorPlatform.instance;

  test('$MethodChannelFlutterDragSelector is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterDragSelector>());
  });

  test('getPlatformVersion', () async {
    FlutterDragSelector flutterDragSelectorPlugin = FlutterDragSelector();
    MockFlutterDragSelectorPlatform fakePlatform = MockFlutterDragSelectorPlatform();
    FlutterDragSelectorPlatform.instance = fakePlatform;

    expect(await flutterDragSelectorPlugin.getPlatformVersion(), '42');
  });
}
