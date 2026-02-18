import 'package:evercrypted/core/entities/chat/chat_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evercrypted/widgets/material_icon_registry.dart';

import '../../../core/entities/contact/contact_model.dart';
import '../../../widgets/circle_avatar_with_active_indicator.dart';
import '../../../ui_constants.dart';

class ContactCard extends ConsumerWidget {
  ContactCard({
    super.key,
    required this.contact,
    required this.isActive,
    required this.onTap,
    this.isParticipantSelect = false,
  });

  final ChatService chatService = ChatService();
  final Contact contact;
  final bool isActive;
  final bool isParticipantSelect;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: CircleAvatarWithActiveIndicator(
        image: contact.avatar?.pic,
        isActive: isActive,
        radius: 28,
        name: contact.displayName ?? contact.email!.split('@')[0],
        avatarColor: contact.avatar?.color != null
            ? Color(int.parse(contact.avatar!.color!))
            : null,
        avatarIcon: contact.avatar?.icon != null
            ? MaterialIconRegistry.iconDataFromCodePoint(
                int.parse(contact.avatar!.icon!))
            : null,
      ),
      title: contact.displayName != null
          ? Text(
              contact.displayName!,
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
            color: Theme.of(context)
                .textTheme
                .bodyLarge!
                .color!
                .withAlpha((255 * 0.64).round()),
          ),
        ),
      ),
      trailing: isParticipantSelect
          ? null
          : SizedBox(
              width: 48,
              child: IconButton(
                icon: const Icon(
                  Icons.chat,
                  color: primaryColor,
                ),
                onPressed: () {
                  chatService.openOneToOneChat(context, ref, contact);
                },
              ),
            ),
      onTap: onTap,
    );
  }
}
