import 'package:evercrypted/core/entities/profile/profile_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_riverpod.g.dart';

@Riverpod(keepAlive: true)
class ProfileNotifier extends _$ProfileNotifier {
  // We initialize the profile to null
  @override
  Profile? build() => null;

  void setProfile(Profile profile) {
    state = profile;
  }
}
