import 'package:evercrypted/core/entities/contact-request/contact_request_model.dart';
import 'package:evercrypted/core/entities/contact-request/contact_request_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SentContactRequestNotifier extends StateNotifier<List<ContactRequest>> {
  // We initialize the list of todos to an empty list
  SentContactRequestNotifier() : super([]);

  final ContactRequestService _contactRequestService = ContactRequestService();

  void setSentRequests() {
    _contactRequestService.getSentContactRequests().then((value) {
      state = [...value];
    });
  }
}

final sentRequestsProvider =
    StateNotifierProvider<SentContactRequestNotifier, List<ContactRequest>>(
        (ref) {
  return SentContactRequestNotifier();
});
