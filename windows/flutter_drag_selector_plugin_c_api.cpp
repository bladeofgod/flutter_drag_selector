#include "include/flutter_drag_selector/flutter_drag_selector_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "flutter_drag_selector_plugin.h"

void FlutterDragSelectorPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  flutter_drag_selector::FlutterDragSelectorPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
