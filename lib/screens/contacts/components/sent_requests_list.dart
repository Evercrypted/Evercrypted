import 'package:evercrypted/core/entities/contact-request/contact_request_model.dart';
import 'package:evercrypted/screens/contacts/components/pending_request_card.dart';
import 'package:flutter/material.dart';

class SentRequestsList extends StatelessWidget {
  const SentRequestsList({super.key, this.sentRequests = const []});

  final List<ContactRequest> sentRequests;

  @override
  Widget build(BuildContext context) {
    // use ref to listen to a provider
    return ListView.builder(
      itemCount: sentRequests.length,
      itemBuilder: (context, index) {
        final item = sentRequests[index];
        return PendingRequestCard(contactRequest: item);
      },
    );
  }
}
