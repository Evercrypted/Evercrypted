import 'package:collection/collection.dart';
import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/entities/chat/chat_service.dart';
import 'package:evercrypted/core/entities/chat/participant_model.dart';
import 'package:evercrypted/core/entities/contact/contact_model.dart';
import 'package:evercrypted/core/entities/contact/contact_riverpod.dart';
import 'package:evercrypted/core/entities/message/message_service.dart';
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
              avatarColor: chat.avatar?.color != null
                  ? Color(int.parse(chat.avatar!.color!))
                  : null,
              avatarIcon: chat.avatar?.icon != null
                  ? IconData(int.parse(chat.avatar!.icon!),
                      fontFamily: 'MaterialIcons')
                  : null,
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
                    Opacity(
                      opacity: 0.64,
                      child: Text(
                        timeago.format(chat.lastMessageTime!),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                _showOptionsBottomSheet(context, chat);
              },
              icon: const Icon(Icons.more_vert, color: Colors.grey),
            )
          ],
        ),
      ),
    );
  }

  void _showOptionsBottomSheet(BuildContext context, Chat chat) {
    // Determine if the current user is the creator
    final currentUserEmail = Auth.getUser?.email?.toLowerCase();
    final currentUserParticipant = chat.participants.firstWhereOrNull(
      (p) => p.email?.toLowerCase() == currentUserEmail,
    );
    final isCreator = currentUserParticipant?.isCreator ?? false;
    final canDelete = isCreator || chat.isOneToOne;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle indicator
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: errorColor.withAlpha((255 * 0.1).toInt()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_sweep,
                        color: errorColor, size: 20),
                  ),
                  title: Text(
                    'Clear messages',
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: contentColorLightThemeSecondary),
                  ),
                  subtitle: const Text(
                    'Delete all messages from this chat locally',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showClearMessagesConfirmationDialog(context, chat);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: errorColor.withAlpha((255 * 0.1).toInt()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      canDelete ? Icons.delete : Icons.exit_to_app,
                      color: errorColor,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    canDelete ? 'Delete chat' : 'Leave chat',
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: contentColorLightThemeSecondary),
                  ),
                  subtitle: Text(
                    canDelete
                        ? 'Permanently delete this chat'
                        : 'Leave this group chat',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteOrLeaveConfirmationDialog(
                        context, chat, canDelete);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showClearMessagesConfirmationDialog(BuildContext context, Chat chat) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear messages'),
          content: const Text(
            'Are you sure you want to delete all messages from this chat? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final messageService = MessageService();
                await messageService.deleteAllMessages(chat.uid);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: secondaryColor,
                      content: Text(
                        'All messages have been cleared',
                        style: TextStyle(color: Colors.white),
                      ),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text(
                'Clear',
                style: TextStyle(color: errorColor),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteOrLeaveConfirmationDialog(
      BuildContext context, Chat chat, bool isDelete) {
    final title = isDelete ? 'Delete chat' : 'Leave chat';
    final content = isDelete
        ? 'Are you sure you want to delete this chat? This action cannot be undone.'
        : 'Are you sure you want to leave this chat?';
    final confirmText = isDelete ? 'Delete' : 'Leave';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                final chatService = ChatService();
                if (isDelete) {
                  chatService.deleteChat(chatUid: chat.uid);
                } else {
                  chatService.leaveChat(chatUid: chat.uid);
                }
              },
              child: Text(
                confirmText,
                style: const TextStyle(color: errorColor),
              ),
            ),
          ],
        );
      },
    );
  }
}
