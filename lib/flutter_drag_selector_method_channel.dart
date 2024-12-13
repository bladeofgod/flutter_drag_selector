import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_drag_selector_platform_interface.dart';

/// An implementation of [FlutterDragSelectorPlatform] that uses method channels.
class MethodChannelFlutterDragSelector extends FlutterDragSelectorPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_drag_selector');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
