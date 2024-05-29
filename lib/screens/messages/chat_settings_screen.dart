import 'package:evercrypted/core/entities/chat/chat_model.dart';
import 'package:evercrypted/screens/messages/components/participant_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatSettingsScreen extends ConsumerStatefulWidget {
  const ChatSettingsScreen(this.chat, {super.key});

  final Chat chat;

  @override
  ChatSettingsScreenState createState() => ChatSettingsScreenState();
}

class ChatSettingsScreenState extends ConsumerState<ChatSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Chat Settings'),
        ),
        body: SingleChildScrollView(
            child: Column(
          children: [
            for (final participant in widget.chat.participants)
              ParticipantCard(participant: participant)
          ],
        )));
  }
}
