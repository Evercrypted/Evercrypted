import 'package:evercrypted/core/entities/contact-request/contact_request_riverpod.dart';
import 'package:evercrypted/ui_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ContactsTabIcon extends ConsumerStatefulWidget {
  final bool active;

  const ContactsTabIcon({super.key, required this.active});

  @override
  ContactsTabIconState createState() => ContactsTabIconState();
}

class ContactsTabIconState extends ConsumerState<ContactsTabIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final receivedRequests = ref.watch(receivedContactRequestsProvider);
    final isThereUnread =
        receivedRequests.where((element) => element.unread == true).isNotEmpty;

    // Apply different styling based on active state
    final iconSize = widget.active ? 42.0 : 24.0;
    final iconColor = widget.active ? Colors.white : Colors.white70;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          Icons.people,
          size: iconSize,
          color: iconColor,
        ),
        if (isThereUnread)
          Positioned(
            right: -3,
            top: -2,
            child: FadeTransition(
              opacity: Tween(begin: 0.4, end: 1.0).animate(_controller),
              child: Container(
                height: widget.active ? 12 : 8,
                width: widget.active ? 12 : 8,
                decoration: BoxDecoration(
                  color: errorColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
              ),
            ),
          )
      ],
    );
  }
}
