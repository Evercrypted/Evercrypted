import 'package:evercrypted/core/entities/contact-request/contact_request_riverpod.dart';
import 'package:evercrypted/screens/contacts/components/pending_request_card.dart';
import 'package:evercrypted/screens/search/components/body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SentRequestsList extends ConsumerWidget {
  const SentRequestsList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // use ref to listen to a provider
    final receivedRequests = ref.watch(receivedRequestsProvider);
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...List.generate(
              demoContactsImage.length,
              (index) => PendingRequestCard(
                  email: "iraklikori@gmail.com",
                  requestSent: DateTime.now().subtract(Duration(hours: 2)),
                  press: () {}),
            )
          ],
        ),
      ),
    );
  }
}
