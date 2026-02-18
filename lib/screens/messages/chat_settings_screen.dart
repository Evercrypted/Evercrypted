import 'dart:async';

import 'package:collection/collection.dart';
import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/entities/chat/chat_model.dart';
import 'package:evercrypted/core/entities/chat/chat_service.dart';
import 'package:evercrypted/core/entities/chat/chat_state.dart';
import 'package:evercrypted/core/entities/chat/participant_model.dart';
import 'package:evercrypted/core/entities/message/message_service.dart';
import 'package:evercrypted/core/entities/contact/contact_model.dart';
import 'package:evercrypted/core/entities/contact/contact_riverpod.dart';
import 'package:evercrypted/core/entities/profile/profile_model.dart';
import 'package:evercrypted/core/entities/profile/profile_riverpod.dart';
import 'package:evercrypted/core/services/block_service.dart';
import 'package:evercrypted/core/services/hidden_chat_service.dart';
import 'package:evercrypted/screens/chats/components/chat_card.dart';
import 'package:evercrypted/screens/contacts/contacts_screen.dart';
import 'package:evercrypted/screens/messages/components/participant_card.dart';
import 'package:evercrypted/ui_constants.dart';
import 'package:evercrypted/widgets/circle_avatar_with_active_indicator.dart';
import 'package:evercrypted/widgets/avatar_editor_bottom_sheet.dart';
import 'package:evercrypted/widgets/password_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatSettingsScreen extends ConsumerStatefulWidget {
  const ChatSettingsScreen(this.chat, {super.key});

  final Chat chat;

  @override
  ChatSettingsScreenState createState() => ChatSettingsScreenState();
}

class ChatSettingsScreenState extends ConsumerState<ChatSettingsScreen> {
  ChatService chatService = ChatService();
  HiddenChatService hiddenChatService = HiddenChatService();
  MessageService messageService = MessageService();
  late Participant user;
  late Chat chat;
  StreamSubscription<List<Chat>>? chatsSubscription;

  @override
  void initState() {
    super.initState();
    chat = widget.chat;
    chatsSubscription = ChatState.subject.listen((chats) {
      late final Chat? chatOrNull;
      chatOrNull = chats.firstWhereOrNull((c) => c.uid == widget.chat.uid);
      if (chatOrNull != null) {
        setState(() {
          chat = chatOrNull!;
        });
      } else {
        Navigator.popUntil(context, (r) => r.isFirst);
      }
    });
  }

  @override
  void dispose() {
    chatsSubscription?.cancel();
    super.dispose();
  }

  Future<bool> _showConfirmationDialog({
    required String title,
    required String content,
    required String confirmText,
    Color? confirmColor,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(title),
              content: Text(content),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(
                    foregroundColor: confirmColor ?? errorColor,
                  ),
                  child: Text(confirmText),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _openAvatarEditor() async {
    final result = await AvatarEditorBottomSheet.show(
      context,
      showNameField: true,
      nameLabel: 'Chat Name',
      initialName: chat.name,
      initialColor: chat.avatar?.color != null
          ? Color(int.parse(chat.avatar!.color!))
          : Colors.blueGrey,
      initialIconCodePoint:
          chat.avatar?.icon != null ? int.tryParse(chat.avatar!.icon!) : null,
    );

    if (result != null) {
      final avatarMap = <String, dynamic>{
        'color': result.color?.value.toString(),
        if (result.iconCodePoint != null)
          'icon': result.iconCodePoint.toString(),
      };

      await chatService.updateChat(
        chatUid: chat.uid,
        name: result.name,
        avatar: avatarMap,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);

    user = chat.participants.firstWhere(
        (p) => p.email?.toLowerCase() == Auth.getUser!.email.toLowerCase());

    Avatar? displayAvatar = chat.avatar;
    if (chat.isOneToOne) {
      final List<Contact> contacts = ref.watch(contactsProvider);
      final otherParticipant =
          chat.participants.firstWhereOrNull((p) => p.uid != Auth.user?.uid);
      if (otherParticipant != null) {
        final contact = contacts.firstWhereOrNull(
            (c) => c.contactPersonUid == otherParticipant.uid);
        if (contact != null) {
          displayAvatar = contact.avatar;
        }
      }
    }

    return Scaffold(
        appBar: AppBar(
          title: const Text('Chat Settings'),
        ),
        body: SingleChildScrollView(
            child: Column(
          children: [
            const SizedBox(height: defaultPadding * 2),
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatarWithActiveIndicator(
                  image: displayAvatar?.pic,
                  radius: 50,
                  name: chat.name ??
                      chatParticipantNames(chat: chat, widgetRef: ref)
                          .join(', '),
                  avatarColor: displayAvatar?.color != null
                      ? Color(int.parse(displayAvatar!.color!))
                      : null,
                  avatarIcon: displayAvatar?.icon != null
                      ? IconData(int.parse(displayAvatar!.icon!),
                          fontFamily: 'MaterialIcons')
                      : null,
                ),
                if (!chat.isOneToOne &&
                    (user.isCreator == true || user.isAdmin == true))
                  Padding(
                    padding: const EdgeInsets.only(left: 5, top: 5),
                    child: InkWell(
                      onTap: () => _openAvatarEditor(),
                      child: const CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 17,
                        child: CircleAvatar(
                          radius: 15,
                          backgroundColor: primaryColor,
                          child: Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  )
              ],
            ),
            const SizedBox(height: defaultPadding),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                child: Column(
                  children: [
                    Text(
                      chat.name ??
                          chatParticipantNames(chat: chat, widgetRef: ref)
                              .join(', '),
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: defaultPadding / 2),
                    Text(
                      'Last Message ${timeago.format(chat.lastMessageTime!)}',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: lightGrey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: defaultPadding),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withAlpha((255 * 0.1).round()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  hiddenChatService.isChatHidden(chat.uid, profile)
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: primaryColor,
                  size: 24,
                ),
              ),
              title: const Text(
                'Hide Chat',
                style: TextStyle(fontSize: 16),
              ),
              subtitle: Text(
                hiddenChatService.isChatHidden(chat.uid, profile)
                    ? 'Chat is hidden'
                    : 'Chat is visible',
                style: const TextStyle(fontSize: 13),
              ),
              trailing: Switch(
                value: hiddenChatService.isChatHidden(chat.uid, profile),
                activeTrackColor: primaryColor,
                onChanged: (value) {
                  if (value) {
                    // Show password dialog to hide
                    PasswordDialog.show(
                      context: context,
                      ref: ref,
                      title: 'Hide Chat',
                      description:
                          'This chat will be hidden from your chat list. You can access it by entering the password in the search field on chats screen.',
                      hintText: 'Enter password to hide chat',
                      confirmButtonText: 'Hide Chat',
                      onConfirm: (password) {
                        hiddenChatService.hideChat(chat.uid, password);
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                    );
                  } else {
                    // Show confirmation to unhide
                    _showConfirmationDialog(
                      title: 'Unhide Chat',
                      content: 'Are you sure you want to unhide this chat?',
                      confirmText: 'Unhide',
                      confirmColor: primaryColor,
                    ).then((confirmed) {
                      if (confirmed) {
                        hiddenChatService.unhideChat(chat.uid);
                      }
                    });
                  }
                },
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: errorColor.withAlpha((255 * 0.1).round()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.delete_sweep,
                  color: errorColor,
                  size: 24,
                ),
              ),
              title: const Text(
                'Clear All Messages',
                style: TextStyle(fontSize: 16),
              ),
              subtitle: const Text(
                'Delete all messages in this chat',
                style: TextStyle(fontSize: 13),
              ),
              onTap: () {
                _showConfirmationDialog(
                  title: 'Clear All Messages',
                  content:
                      'Are you sure you want to delete all messages in this chat? This action cannot be undone.',
                  confirmText: 'Clear All',
                ).then((confirmed) async {
                  if (confirmed) {
                    try {
                      await messageService.deleteAllMessages(chat.uid);
                      if (context.mounted) {
                        // Pop back to messages screen with result indicating messages were cleared
                        Navigator.pop(context, true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('All messages deleted'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to delete messages: $e'),
                          ),
                        );
                      }
                    }
                  }
                });
              },
            ),
            if (!chat.isOneToOne) ...[
              const SizedBox(height: defaultPadding),
              for (final participant in chat.participants
                  .where((p) => p.email != Auth.getUser!.email))
                ParticipantCard(
                  user: user,
                  participant: participant,
                  participantsLenght: chat.participants.length,
                  remove: () => _showConfirmationDialog(
                    title: 'Remove Participant',
                    content:
                        'Are you sure you want to remove ${participant.name ?? participant.email} from this chat?',
                    confirmText: 'Remove',
                  ).then((confirmed) {
                    if (confirmed) {
                      chatService.removeParticipantFromChat(
                          chat: chat, participant: participant);
                    }
                  }),
                ),
            ],
            if ((user.isCreator || user.isAdmin) && !chat.isOneToOne) ...[
              const SizedBox(height: defaultPadding),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ContactsScreen(
                          isParticipantSelect: true,
                          isAddNewParticipants: true,
                          participants: chat.participants
                              .where((p) => p.email != Auth.getUser!.email)
                              .toList(),
                        ),
                      ),
                    ).then((val) {
                      if (val != null && val.length > 0) {
                        chatService.addParticipantsToChat(
                            chat: chat, participants: val);
                      }
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Participant from Contacts'),
                ),
              )
            ],
            if (user.isCreator || chat.isOneToOne) ...[
              const SizedBox(height: defaultPadding),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: errorColor,
                  ),
                  onPressed: () {
                    _showConfirmationDialog(
                      title: 'Confirm Delete',
                      content: 'Are you sure you want to delete this chat?',
                      confirmText: 'Delete',
                    ).then((confirmed) {
                      if (confirmed && context.mounted) {
                        Navigator.popUntil(context, (route) => route.isFirst);
                        ModalRoute.of(context)!.completed.then(
                            (_) => chatService.deleteChat(chatUid: chat.uid));
                      }
                    });
                  },
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Delete Chat',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: defaultPadding / 2),
            ],
            if (chat.isOneToOne) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  onPressed: () {
                    // Get the other participant for 1-on-1 chat
                    final otherParticipant = chat.participants.firstWhere((p) =>
                        p.email?.toLowerCase() !=
                        Auth.getUser!.email.toLowerCase());
                    _showConfirmationDialog(
                      title: 'Block User',
                      content:
                          'Are you sure you want to block ${otherParticipant.email}? They won\'t be able to send you messages or contact requests. This will also delete the chat.',
                      confirmText: 'Block',
                    ).then((confirmed) async {
                      if (confirmed) {
                        if (otherParticipant.uid == null) return;
                        final success =
                            await BlockService.blockUser(otherParticipant.uid!);
                        if (success) {
                          if (context.mounted) {
                            Navigator.popUntil(
                                context, (route) => route.isFirst);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('User blocked successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Failed to block user. Please try again.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    });
                  },
                  icon: const Icon(
                    Icons.block,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Block User',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
            if (!user.isCreator && !chat.isOneToOne) ...[
              const SizedBox(height: defaultPadding),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: errorColor,
                  ),
                  onPressed: () {
                    _showConfirmationDialog(
                      title: 'Confirm Leave',
                      content: 'Are you sure you want to leave this chat?',
                      confirmText: 'Leave',
                    ).then((confirmed) {
                      if (confirmed && context.mounted) {
                        Navigator.popUntil(context, (route) => route.isFirst);
                        ModalRoute.of(context)!.completed.then(
                            (_) => chatService.leaveChat(chatUid: chat.uid));
                      }
                    });
                  },
                  icon: const Icon(
                    Icons.exit_to_app,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Leave Chat',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ]
          ],
        )));
  }
}
