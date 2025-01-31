
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

///Defines default property values for descendant [CursorSelectorWidget] widgets.
class CursorSelectorThemeData with Diagnosticable {

  ///Selected-area's decoration when cursor dragging.
  final Decoration selectedAreaDecoration;

  CursorSelectorThemeData({required this.selectedAreaDecoration});

  @override
  int get hashCode => selectedAreaDecoration.hashCode;

  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(runtimeType != other.runtimeType) {
      return false;
    }
    return other == selectedAreaDecoration;
  }

}


///Applies a cursor-selector theme to descendant [CursorSelectorWidget] widgets.
class CursorSelectorTheme extends InheritedTheme {

  const CursorSelectorTheme({super.key, required super.child, required this.data});

  ///The properties used for all descendant [CursorSelectorWidget] widgets.
  final CursorSelectorThemeData data;

  static CursorSelectorThemeData? of(BuildContext context) {
    final CursorSelectorTheme? selectorTheme = context.dependOnInheritedWidgetOfExactType<CursorSelectorTheme>();
    return selectorTheme?.data;
  }

  @override
  bool updateShouldNotify(covariant CursorSelectorTheme oldWidget) => data != oldWidget.data;

  @override
  Widget wrap(BuildContext context, Widget child) {
    return CursorSelectorTheme(data: data, child: child,);
  }
}









