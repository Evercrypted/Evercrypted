// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'navigation_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Navigation)
const navigationProvider = NavigationProvider._();

final class NavigationProvider
    extends $NotifierProvider<Navigation, NavigationState> {
  const NavigationProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'navigationProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$navigationHash();

  @$internal
  @override
  Navigation create() => Navigation();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NavigationState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NavigationState>(value),
    );
  }
}

String _$navigationHash() => r'3510a977d2243b04b4db45c321e11be2257ced83';

abstract class _$Navigation extends $Notifier<NavigationState> {
  NavigationState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<NavigationState, NavigationState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<NavigationState, NavigationState>,
        NavigationState,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}
