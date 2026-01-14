// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_request_riverpod.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SentContactRequests)
final sentContactRequestsProvider = SentContactRequestsProvider._();

final class SentContactRequestsProvider
    extends $NotifierProvider<SentContactRequests, List<ContactRequest>> {
  SentContactRequestsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'sentContactRequestsProvider',
          isAutoDispose: false,
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
    r'046a0cfd3d0b246e922961320fe25c7c5ecfca51';

abstract class _$SentContactRequests extends $Notifier<List<ContactRequest>> {
  List<ContactRequest> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<ContactRequest>, List<ContactRequest>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<List<ContactRequest>, List<ContactRequest>>,
        List<ContactRequest>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(ReceivedContactRequests)
final receivedContactRequestsProvider = ReceivedContactRequestsProvider._();

final class ReceivedContactRequestsProvider
    extends $NotifierProvider<ReceivedContactRequests, List<ContactRequest>> {
  ReceivedContactRequestsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'receivedContactRequestsProvider',
          isAutoDispose: false,
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
    r'f4bb4226617ef2b4d9eace0022cd8b6aba6cfeb9';

abstract class _$ReceivedContactRequests
    extends $Notifier<List<ContactRequest>> {
  List<ContactRequest> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<ContactRequest>, List<ContactRequest>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<List<ContactRequest>, List<ContactRequest>>,
        List<ContactRequest>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
