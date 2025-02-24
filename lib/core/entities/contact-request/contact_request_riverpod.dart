import 'package:evercrypted/core/entities/contact-request/contact_request_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SentContactRequestsNotifier extends StateNotifier<List<ContactRequest>> {
  // We initialize the list of todos to an empty list
  SentContactRequestsNotifier() : super([]);

  void setSentRequests(List<ContactRequest> sentRequests) {
    state = [...sentRequests];
  }

  void addSentRequest(ContactRequest sentRequest) {
    state = [sentRequest, ...state];
  }
}

final sentRequestsProvider =
    StateNotifierProvider<SentContactRequestsNotifier, List<ContactRequest>>(
        (ref) {
  return SentContactRequestsNotifier();
});

class ReceivedContactRequestsNotifier
    extends StateNotifier<List<ContactRequest>> {
  // We initialize the list of todos to an empty list
  ReceivedContactRequestsNotifier() : super([]);

  void setReceivedRequests(List<ContactRequest> receivedRequests) {
    state = [...receivedRequests];
  }

  void addReceivedRequest(ContactRequest receivedRequest) {
    state = [receivedRequest, ...state];
  }
}

final receivedRequestsProvider = StateNotifierProvider<
    ReceivedContactRequestsNotifier, List<ContactRequest>>((ref) {
  return ReceivedContactRequestsNotifier();
});
