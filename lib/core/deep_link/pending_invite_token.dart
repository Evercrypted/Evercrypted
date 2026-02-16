import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pending_invite_token.g.dart';

@Riverpod(keepAlive: true)
class PendingInviteTokenNotifier extends _$PendingInviteTokenNotifier {
  @override
  String? build() => null;

  void set(String? token) {
    state = token;
  }

  void clear() {
    state = null;
  }
}
