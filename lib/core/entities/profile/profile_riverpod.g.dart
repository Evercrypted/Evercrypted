// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_riverpod.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ProfileNotifier)
const profileProvider = ProfileNotifierProvider._();

final class ProfileNotifierProvider
    extends $NotifierProvider<ProfileNotifier, Profile?> {
  const ProfileNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'profileProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$profileNotifierHash();

  @$internal
  @override
  ProfileNotifier create() => ProfileNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Profile? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Profile?>(value),
    );
  }
}

String _$profileNotifierHash() => r'36287c3e01169be7e28ebe20c10755ef4a5d8d79';

abstract class _$ProfileNotifier extends $Notifier<Profile?> {
  Profile? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<Profile?, Profile?>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<Profile?, Profile?>, Profile?, Object?, Object?>;
    element.handleValue(ref, created);
  }
}
