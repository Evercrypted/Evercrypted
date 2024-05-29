import 'package:evercrypted/core/entities/chat/chat_service.dart';
import 'package:evercrypted/screens/contacts/contact_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/entities/contact/contact_model.dart';
import '../../../widgets/circle_avatar_with_active_indicator.dart';
import '../../../ui_constants.dart';

class ContactCard extends ConsumerWidget {
  ContactCard({
    super.key,
    required this.contact,
    required this.isActive,
  });

  final ChatService chatService = ChatService();
  final Contact contact;
  final bool isActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: CircleAvatarWithActiveIndicator(
        image: contact.avatar?.pic,
        isActive: isActive,
        radius: 28,
        name: contact.name ?? contact.email!.split('@')[0],
      ),
      title: contact.name != null
          ? Text(
              contact.name!,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            )
          : Text(
              contact.email!.split('@')[0],
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: defaultPadding / 2),
        child: Text(
          contact.email!,
          style: TextStyle(
            color:
                Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.64),
          ),
        ),
      ),
      trailing: IconButton(
        icon: const Icon(
          Icons.chat,
          color: primaryColor,
        ),
        onPressed: () {
          chatService.openChat(context, ref, contact);
        },
      ),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return ContactScreen(
            contact: contact,
          );
        }));
      },
    );
  }
}
