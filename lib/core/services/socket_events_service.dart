import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../entities/contact-request/contact_request_model.dart';
import '../entities/contact-request/contact_request_riverpod.dart';

class SocketEventsService {
  handleEvent(WidgetRef ref, String channel, String type, dynamic data) {
    switch (channel) {
      case 'contactRequest':
        switch (type) {
          case 'contactRequestCreated':
            ref
                .read(receivedRequestsProvider.notifier)
                .addReceivedRequest(ContactRequest.fromJson(data['payload']));
            break;
          default:
            print('Unknown Contact Request Event');
            print(data);
        }
        break;
      default:
        print('Unknown Event');
        print(data);
    }
  }
}
