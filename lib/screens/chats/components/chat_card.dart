import 'package:evercrypted/core/auth.dart';
import 'package:flutter/material.dart';

import '../../../core/entities/chat/chat_model.dart';
import '../../../widgets/circle_avatar_with_active_indicator.dart';
import '../../../ui_constants.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatCard extends StatelessWidget {
  ChatCard({
    super.key,
    required this.chat,
    required this.press,
    this.isActive = false,
  });

  final Chat chat;
  final VoidCallback press;
  final userId = Auth.user?.uid;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: press,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: defaultPadding, vertical: defaultPadding * 0.75),
        child: Row(
          children: [
            CircleAvatarWithActiveIndicator(
              image: chat.avatar?.pic,
              isActive: true,
              radius: 28,
              name: chat.name ??
                  chat.participants
                      .where((element) => element.uid != userId)
                      .map((e) => e.name ?? e.email!.split('@')[0])
                      .toList()
                      .join(', '),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chat.name ??
                          chat.participants
                              .where((element) => element.uid != userId)
                              .map((e) => e.name ?? e.email!.split('@')[0])
                              .toList()
                              .join(', '),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 8),
                    const Opacity(
                      opacity: 0.64,
                      child: Text(
                        'Some Text Here',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Opacity(
              opacity: 0.64,
              child: Text(timeago.format(chat.lastMessageTime!)),
            ),
          ],
        ),
      ),
    );
  }
}
