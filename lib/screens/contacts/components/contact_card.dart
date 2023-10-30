import 'package:evercrypted/core/entities/chat/chat_model.dart';
import 'package:evercrypted/core/entities/chat/chat_riverpod.dart';
import 'package:evercrypted/core/entities/chat/chat_service.dart';
import 'package:evercrypted/core/entities/profile/profile_model.dart';
import 'package:evercrypted/core/entities/profile/profile_riverpod.dart';
import 'package:evercrypted/screens/chats/chats_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/entities/contact/contact_model.dart';
import '../../../widgets/circle_avatar_with_active_indicator.dart';
import '../../../ui_constants.dart';

class ContactCard extends ConsumerWidget {
  ContactCard({
    Key? key,
    required this.contact,
    required this.isActive,
    required this.press,
  }) : super(key: key);

  final ChatService chatService = ChatService();
  final Contact contact;
  final bool isActive;
  final VoidCallback press;

  openChat(BuildContext context, WidgetRef ref) {
    List<Chat> chats = ref.read(chatsProvider);
    if (chats.any((element) =>
        element.participants?.length == 2 &&
        element.participants?.contains(contact.contactPersonUid) == true)) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const ChatsScreen(),
        ),
      );
    } else {
      NewChatDTO newChat = NewChatDTO(contact: contact.contactPersonUid!);
      chatService.createNewChat(newChat).then((value) {
        print(value);
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => const ChatsScreen(),
        //   ),
        // );
      });
    }
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
        icon: const Icon(
          Icons.chat,
          color: primaryColor,
        ),
        onPressed: () {
          openChat(context, ref);
        },
      ),
      onTap: () {},
    );
  }
}
