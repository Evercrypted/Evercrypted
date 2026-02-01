import 'package:evercrypted/core/entities/chat/participant_model.dart';
import 'package:evercrypted/core/services/block_service.dart';
import 'package:evercrypted/core/entities/contact/contact_model.dart';
import 'package:evercrypted/core/entities/contact/contact_riverpod.dart';
import 'package:evercrypted/core/entities/contact/contact_service.dart';
import 'package:evercrypted/core/entities/profile/profile_model.dart';
import 'package:evercrypted/core/entities/profile/profile_riverpod.dart';
import 'package:evercrypted/ui_constants.dart';
import 'package:evercrypted/widgets/circle_avatar_with_active_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';

class ParticipantCard extends ConsumerWidget {
  final Participant user;
  final Participant participant;
  final int participantsLenght;
  final Function remove;

  const ParticipantCard(
      {super.key,
      required this.participant,
      required this.participantsLenght,
      required this.user,
      required this.remove});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactService = ContactService();
    final contacts = ref.watch(contactsProvider);
    final Contact? contact = contacts.firstWhereOrNull(
      (c) => c.contactPersonUid == participant.uid,
    );
    final profile = ref.watch(profileProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: defaultPadding * 2, vertical: defaultPadding * 0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatarWithActiveIndicator(
                  image: participant.avatar?.pic,
                  radius: 24,
                  name: participant.name ?? participant.email,
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(
                        width: 12,
                      ),
                      Expanded(
                        child: Text(
                          participant.name ?? participant.email!,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              _showOptionsBottomSheet(
                  context, contact, profile, contactService);
            },
            icon: const Icon(Icons.more_vert),
          )
        ],
      ),
    );
  }

  void _showOptionsBottomSheet(BuildContext context, Contact? contact,
      Profile? profile, contactService) {
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
                if (participantsLenght > 2 && (user.isAdmin || user.isCreator))
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: errorColor.withAlpha((255 * 0.1).toInt()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          const Icon(Icons.delete, color: errorColor, size: 20),
                    ),
                    title: Text('Remove from chat',
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: contentColorLightThemeSecondary)),
                    subtitle: const Text(
                      'Remove this participant from the chat',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      remove();
                    },
                  ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha((255 * 0.1).toInt()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        const Icon(Icons.block, color: Colors.orange, size: 20),
                  ),
                  title: Text(
                    'Block user',
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: contentColorLightThemeSecondary),
                  ),
                  subtitle: const Text(
                    'Block this user from contacting you',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Block User'),
                          content: Text(
                              'Are you sure you want to block ${participant.name ?? participant.email}?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                if (participant.uid == null) return;
                                final success = await BlockService.blockUser(
                                    participant.uid!);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(success
                                          ? 'User blocked successfully'
                                          : 'Failed to block user'),
                                      backgroundColor:
                                          success ? Colors.green : Colors.red,
                                    ),
                                  );
                                }
                              },
                              style: TextButton.styleFrom(
                                  foregroundColor: Colors.orange),
                              child: const Text('Block'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}
