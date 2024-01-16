import 'package:evercrypted/core/entities/contact-request/contact_request_model.dart';
import 'package:evercrypted/screens/contacts/components/pending_request_card.dart';
import 'package:flutter/material.dart';

class ReceivedRequestsList extends StatelessWidget {
  const ReceivedRequestsList({super.key, this.receivedRequests = const []});

  final List<ContactRequest> receivedRequests;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: receivedRequests.length,
      itemBuilder: (context, index) {
        final item = receivedRequests[index];
        return PendingRequestCard(
          isReceived: true,
          contactRequest: item,
        );
      },
    );
  }
}
