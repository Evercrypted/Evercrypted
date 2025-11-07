import 'package:evercrypted/core/entities/contact-request/contact_request_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'contact_request_riverpod.g.dart';

@Riverpod(keepAlive: true)
class SentContactRequests extends _$SentContactRequests {
  // We initialize the list of sent requests to an empty list
  @override
  List<ContactRequest> build() => [];

  void setSentRequests(List<ContactRequest> sentRequests) {
    state = [...sentRequests];
  }

  void addSentRequest(ContactRequest sentRequest) {
    state = [sentRequest, ...state];
  }
}

@Riverpod(keepAlive: true)
class ReceivedContactRequests extends _$ReceivedContactRequests {
  // We initialize the list of received requests to an empty list
  @override
  List<ContactRequest> build() => [];

  void setReceivedRequests(List<ContactRequest> receivedRequests) {
    state = [...receivedRequests];
  }

  void addReceivedRequest(ContactRequest receivedRequest) {
    state = [receivedRequest, ...state];
  }
}
