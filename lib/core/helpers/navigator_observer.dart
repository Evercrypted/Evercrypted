import 'package:flutter/material.dart';

class NavObserver extends NavigatorObserver {
  NavObserver({required this.onChange});
  final Function() onChange;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onChange();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onChange();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) {
      onChange();
    }
  }
}
