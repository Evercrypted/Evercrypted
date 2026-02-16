// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_invite_token.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PendingInviteTokenNotifier)
final pendingInviteTokenProvider = PendingInviteTokenNotifierProvider._();

final class PendingInviteTokenNotifierProvider
    extends $NotifierProvider<PendingInviteTokenNotifier, String?> {
  PendingInviteTokenNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'pendingInviteTokenProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$pendingInviteTokenNotifierHash();

  @$internal
  @override
  PendingInviteTokenNotifier create() => PendingInviteTokenNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$pendingInviteTokenNotifierHash() =>
    r'91112f6b387162629ecbb1da682cc02fcdfd8cbe';

abstract class _$PendingInviteTokenNotifier extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<String?, String?>, String?, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}
