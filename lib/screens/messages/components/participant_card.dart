import 'package:evercrypted/core/entities/chat/chat_model.dart';
import 'package:flutter/material.dart';

class ParticipantCard extends StatelessWidget {
  final Participant participant;

  const ParticipantCard({super.key, required this.participant});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(participant.name ?? participant.email!),
        subtitle: Text(participant.lastSawChat.toString()),
      ),
    );
  }
}
