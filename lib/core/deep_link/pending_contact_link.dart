import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pending_contact_link.g.dart';

class PendingContactLink {
  final String email;
  final String message;

  PendingContactLink({required this.email, required this.message});
}

@Riverpod(keepAlive: true)
class PendingContactLinkNotifier extends _$PendingContactLinkNotifier {
  @override
  PendingContactLink? build() => null;

  void set(PendingContactLink? link) {
    state = link;
  }

  void clear() {
    state = null;
  }
}
