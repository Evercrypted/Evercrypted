// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_request_riverpod.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SentContactRequests)
const sentContactRequestsProvider = SentContactRequestsProvider._();

final class SentContactRequestsProvider
    extends $NotifierProvider<SentContactRequests, List<ContactRequest>> {
  const SentContactRequestsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'sentContactRequestsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$sentContactRequestsHash();

  @$internal
  @override
  SentContactRequests create() => SentContactRequests();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ContactRequest> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ContactRequest>>(value),
    );
  }
}

String _$sentContactRequestsHash() =>
    r'6aa2e3047e2cfe2f4191323209eff9842fa1a312';

abstract class _$SentContactRequests extends $Notifier<List<ContactRequest>> {
  List<ContactRequest> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<List<ContactRequest>, List<ContactRequest>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<List<ContactRequest>, List<ContactRequest>>,
        List<ContactRequest>,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}

@ProviderFor(ReceivedContactRequests)
const receivedContactRequestsProvider = ReceivedContactRequestsProvider._();

final class ReceivedContactRequestsProvider
    extends $NotifierProvider<ReceivedContactRequests, List<ContactRequest>> {
  const ReceivedContactRequestsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'receivedContactRequestsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$receivedContactRequestsHash();

  @$internal
  @override
  ReceivedContactRequests create() => ReceivedContactRequests();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ContactRequest> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ContactRequest>>(value),
    );
  }
}

String _$receivedContactRequestsHash() =>
    r'e068add3cfe894ce17ed3df36e52aaa857579354';

abstract class _$ReceivedContactRequests
    extends $Notifier<List<ContactRequest>> {
  List<ContactRequest> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<List<ContactRequest>, List<ContactRequest>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<List<ContactRequest>, List<ContactRequest>>,
        List<ContactRequest>,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}
