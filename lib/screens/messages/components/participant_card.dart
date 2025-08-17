import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/entities/chat/participant_model.dart';
import 'package:evercrypted/core/entities/contact/contact_riverpod.dart';
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
    final contacts = ref.watch(contactsProvider);
    final contact = contacts.firstWhereOrNull(
      (c) => c.contactPersonUid == participant.uid,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: defaultPadding * 2, vertical: defaultPadding * 0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              children: [
                CircleAvatarWithActiveIndicator(
                  image: participant.avatar?.pic,
                  radius: 24,
                  name: participant.name ?? participant.email,
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: defaultPadding),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width -
                        4 * defaultPadding -
                        130,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            participant.name ?? participant.email!,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        if (contact != null && !contact.hasActivated) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Free',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (participantsLenght > 2 && (user.isAdmin || user.isCreator))
            IconButton(
              onPressed: () {
                remove();
              },
              icon: const Icon(Icons.delete, color: errorColor),
            )
        ],
      ),
    );
  }
}
