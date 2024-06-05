import 'package:collection/collection.dart';
import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/entities/contact/contact_model.dart';
import 'package:evercrypted/core/entities/contact/contact_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/entities/chat/chat_model.dart';
import '../../../widgets/circle_avatar_with_active_indicator.dart';
import '../../../ui_constants.dart';
import 'package:timeago/timeago.dart' as timeago;

List<String> chatParticipantNames({chat, widgetRef}) {
  final List<Contact> contacts = widgetRef.read(contactsProvider);
  return chat.participants
      .where((element) => element.uid != Auth.user?.uid)
      .map<String>((Participant e) {
    final Contact? contactFound = contacts
        .firstWhereOrNull((element) => element.contactPersonUid == e.uid);
    if (contactFound != null && contactFound.name != null) {
      return contactFound.name!;
    } else {
      return e.name ?? e.email!.split('@')[0];
    }
  }).toList();
}

class ChatCard extends ConsumerWidget {
  const ChatCard({
    super.key,
    required this.chat,
    required this.press,
    this.isActive = false,
  });

  final Chat chat;
  final VoidCallback press;
  final bool isActive;

  @override
  Widget build(BuildContext context, ref) {
    final participantNames =
        chatParticipantNames(chat: chat, widgetRef: ref).join(', ');

    return InkWell(
      onTap: press,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: defaultPadding, vertical: defaultPadding * 0.75),
        child: Row(
          children: [
            CircleAvatarWithActiveIndicator(
              image: chat.avatar?.pic,
              radius: 28,
              name: chat.name ?? participantNames,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chat.name ?? participantNames,
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
