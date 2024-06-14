import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/entities/chat/chat_model.dart';
import 'package:evercrypted/ui_constants.dart';
import 'package:evercrypted/widgets/circle_avatar_with_active_indicator.dart';
import 'package:flutter/material.dart';

class ParticipantCard extends StatelessWidget {
  final Participant user;
  final Participant participant;
  final int participantsLenght;

  ParticipantCard(
      {super.key,
      required this.participant,
      required this.participantsLenght,
      required this.user});

  final String userEmail = Auth.getUser!.email;

  @override
  Widget build(BuildContext context) {
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
                    child: Text(
                      participant.name ?? participant.email!,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (participantsLenght > 2 && (user.isAdmin || user.isCreator))
            IconButton(
              onPressed: () {
                // TODO remove participant
              },
              icon: const Icon(Icons.delete, color: Colors.red),
            )
        ],
      ),
    );
  }
}
