// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'evercrypted_keyboard_riverpod.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Notifier class to manage keyboard state changes

@ProviderFor(KeyboardNotifier)
final keyboardProvider = KeyboardNotifierProvider._();

/// Notifier class to manage keyboard state changes
final class KeyboardNotifierProvider
    extends $NotifierProvider<KeyboardNotifier, KeyboardState> {
  /// Notifier class to manage keyboard state changes
  KeyboardNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'keyboardProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$keyboardNotifierHash();

  @$internal
  @override
  KeyboardNotifier create() => KeyboardNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(KeyboardState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<KeyboardState>(value),
    );
  }
}

String _$keyboardNotifierHash() => r'cd487be9758fa1aef38ecf73434153908c7fee3a';

/// Notifier class to manage keyboard state changes

abstract class _$KeyboardNotifier extends $Notifier<KeyboardState> {
  KeyboardState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<KeyboardState, KeyboardState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<KeyboardState, KeyboardState>,
        KeyboardState,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
