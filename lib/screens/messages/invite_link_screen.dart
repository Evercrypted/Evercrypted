import 'package:evercrypted/core/entities/chat/chat_model.dart';
import 'package:evercrypted/screens/messages/components/invite_link_section.dart';
import 'package:evercrypted/ui_constants.dart';
import 'package:flutter/material.dart';

class InviteLinkScreen extends StatefulWidget {
  final Chat chat;

  const InviteLinkScreen({super.key, required this.chat});

  @override
  State<InviteLinkScreen> createState() => _InviteLinkScreenState();
}

class _InviteLinkScreenState extends State<InviteLinkScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invite Links'),
        foregroundColor: primaryColor,
      ),
      body: SingleChildScrollView(
        child: InviteLinkSection(
          chat: widget.chat,
          onChatUpdated: () => setState(() {}),
        ),
      ),
    );
  }
}
