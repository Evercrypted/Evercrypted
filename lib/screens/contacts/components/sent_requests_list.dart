import 'package:evercrypted/core/entities/contact-request/contact_request_riverpod.dart';
import 'package:evercrypted/screens/contacts/components/pending_request_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SentRequestsList extends ConsumerWidget {
  const SentRequestsList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // use ref to listen to a provider
    final sentRequests = ref.watch(sentRequestsProvider);
    return ListView.builder(
      itemCount: sentRequests.length,
      itemBuilder: (context, index) {
        final item = sentRequests[index];
        return PendingRequestCard(
          isReceived: true,
          message: item.message ?? "",
          email: item.recipientEmail ?? "",
          requestSent: item.timeSent ?? DateTime.now(),
          press: () {},
        );
      },
    );
  }
}
