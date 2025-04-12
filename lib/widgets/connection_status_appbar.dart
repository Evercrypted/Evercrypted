import 'dart:async';
import 'package:evercrypted/core/socket/socket.dart';
import 'package:evercrypted/ui_constants.dart';
import 'package:flutter/material.dart';

class ConnectionStatusAppbar extends StatefulWidget
    implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final bool? isConnected;

  const ConnectionStatusAppbar(
      {super.key, this.title, this.actions, this.isConnected});

  @override
  Size get preferredSize => title != null || actions != null
      ? const Size.fromHeight(56.0)
      : const Size.fromHeight(20);

  @override
  State<ConnectionStatusAppbar> createState() => _ConnectionStatusAppbarState();
}

class _ConnectionStatusAppbarState extends State<ConnectionStatusAppbar> {
  bool isConnected = true;
  StreamSubscription? isConnectedListener;

  @override
  void initState() {
    super.initState();

    setIsConnected();
  }

  @override
  void didUpdateWidget(covariant ConnectionStatusAppbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    setIsConnected();
  }

  setIsConnected() {
    if (widget.isConnected != null) {
      setState(() {
        isConnected = widget.isConnected!;
      });
    } else {
      isConnectedListener =
          ChatSocket.isConnectedSubject.stream.listen((isConnected) {
        if (mounted) {
          setState(() {
            this.isConnected = isConnected;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    isConnectedListener?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isConnected) {
      return widget.title != null || widget.actions != null
          ? AppBar(
              title: widget.title,
              actions: widget.actions,
            )
          : AppBar();
    } else {
      return AppBar(
        title: widget.title != null
            ? Column(children: [
                Container(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: const Text(
                      "We're not able to connect with the server",
                      style: TextStyle(color: errorColor, fontSize: 12),
                    )),
                widget.title!,
                const SizedBox(height: 5),
              ])
            : const Text(
                "We're not able to connect with the server",
                style: TextStyle(color: errorColor, fontSize: 15),
              ),
        actions: widget.actions,
        centerTitle: true,
        toolbarHeight: widget.title != null ? 100 : 25,
      );
    }
  }
}
