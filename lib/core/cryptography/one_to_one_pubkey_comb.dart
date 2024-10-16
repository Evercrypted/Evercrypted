import 'package:evercrypted/core/entities/chat/participant_model.dart';

String? oneToOnePubkeyComb(List<Participant> participants) {
  if (participants.any((p) => p.pubKey == null)) {
    return null;
  }
  final List<String> pubKeys = participants.map((e) => e.pubKey!).toList();
  pubKeys.sort();
  return pubKeys.join();
}
