import 'package:evercrypted/core/services/app_state_riverpod.dart';
import 'package:flutter/material.dart';

class AppbarService {
  static AppBar? getAppbar(ref, Widget? title, List<Widget>? actions) {
    final isConnected = ref.watch(appStateProvider).isConnected;
    if (isConnected) {
      return title != null && actions != null
          ? AppBar(
              title: title,
              actions: actions,
            )
          : null;
    } else {
      return AppBar(
        title: title != null
            ? Column(children: [
                Container(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: const Text(
                      "We're not able to connect with the server",
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    )),
                title
              ])
            : const Text(
                "We're not able to connect with the server",
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
        actions: actions,
        centerTitle: true,
        backgroundColor: title != null ? Colors.white : Colors.red,
        toolbarHeight: title != null ? 100 : 25,
      );
    }
  }
}
