
import 'flutter_drag_selector_platform_interface.dart';

class FlutterDragSelector {
  Future<String?> getPlatformVersion() {
    return FlutterDragSelectorPlatform.instance.getPlatformVersion();
  }
}
