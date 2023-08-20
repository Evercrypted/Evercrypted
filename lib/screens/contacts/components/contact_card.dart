import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/entities/contact/contact_model.dart';
import '../../../widgets/circle_avatar_with_active_indicator.dart';
import '../../../ui_constants.dart';

class ContactCard extends ConsumerWidget {
  const ContactCard({
    Key? key,
    required this.contact,
    required this.isActive,
    required this.press,
  }) : super(key: key);

  final Contact contact;
  final bool isActive;
  final VoidCallback press;

  openChat(WidgetRef ref) {
    print(contact.uid);
  }

  checkIfChatIsOpenWithContact(WidgetRef ref) {
    print(contact.uid);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: CircleAvatarWithActiveIndicator(
        image: contact.avatar!.pic,
        isActive: isActive,
        radius: 28,
        name: contact.name ?? contact.email!.split('@')[0],
      ),
      title: contact.name != null
          ? Text(contact.name!)
          : Text(contact.email!.split('@')[0]),
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
        icon: Icon(
          Icons.chat,
          color: primaryColor,
        ),
        onPressed: () {
          openChat(ref);
        },
      ),
      onTap: () {},
    );
  }
}
