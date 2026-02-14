// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_contact_link.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PendingContactLinkNotifier)
final pendingContactLinkProvider = PendingContactLinkNotifierProvider._();

final class PendingContactLinkNotifierProvider
    extends $NotifierProvider<PendingContactLinkNotifier, PendingContactLink?> {
  PendingContactLinkNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'pendingContactLinkProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$pendingContactLinkNotifierHash();

  @$internal
  @override
  PendingContactLinkNotifier create() => PendingContactLinkNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PendingContactLink? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PendingContactLink?>(value),
    );
  }
}

String _$pendingContactLinkNotifierHash() =>
    r'2ee5e625fad4d2f7f177c31d5a9674953c1a0cd4';

abstract class _$PendingContactLinkNotifier
    extends $Notifier<PendingContactLink?> {
  PendingContactLink? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<PendingContactLink?, PendingContactLink?>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<PendingContactLink?, PendingContactLink?>,
        PendingContactLink?,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
