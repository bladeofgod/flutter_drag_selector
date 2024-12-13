import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_drag_selector_method_channel.dart';

abstract class FlutterDragSelectorPlatform extends PlatformInterface {
  /// Constructs a FlutterDragSelectorPlatform.
  FlutterDragSelectorPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterDragSelectorPlatform _instance = MethodChannelFlutterDragSelector();

  /// The default instance of [FlutterDragSelectorPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterDragSelector].
  static FlutterDragSelectorPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterDragSelectorPlatform] when
  /// they register themselves.
  static set instance(FlutterDragSelectorPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
