// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'evercrypted_text_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// A provider family that creates and manages EvercryptedTextController instances
/// Automatically handles disposal when the provider is disposed
/// Usage: ref.watch(evercryptedTextControllerProvider('key'))

@ProviderFor(EvercryptedTextControllerNotifier)
final evercryptedTextControllerProvider =
    EvercryptedTextControllerNotifierFamily._();

/// A provider family that creates and manages EvercryptedTextController instances
/// Automatically handles disposal when the provider is disposed
/// Usage: ref.watch(evercryptedTextControllerProvider('key'))
final class EvercryptedTextControllerNotifierProvider extends $NotifierProvider<
    EvercryptedTextControllerNotifier, EvercryptedTextController> {
  /// A provider family that creates and manages EvercryptedTextController instances
  /// Automatically handles disposal when the provider is disposed
  /// Usage: ref.watch(evercryptedTextControllerProvider('key'))
  EvercryptedTextControllerNotifierProvider._(
      {required EvercryptedTextControllerNotifierFamily super.from,
      required (
        String, {
        String? initialText,
      })
          super.argument})
      : super(
          retry: null,
          name: r'evercryptedTextControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() =>
      _$evercryptedTextControllerNotifierHash();

  @override
  String toString() {
    return r'evercryptedTextControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  EvercryptedTextControllerNotifier create() =>
      EvercryptedTextControllerNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EvercryptedTextController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EvercryptedTextController>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is EvercryptedTextControllerNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$evercryptedTextControllerNotifierHash() =>
    r'073267410d9bd8becdf95f65b461dc65e7f6c8af';

/// A provider family that creates and manages EvercryptedTextController instances
/// Automatically handles disposal when the provider is disposed
/// Usage: ref.watch(evercryptedTextControllerProvider('key'))

final class EvercryptedTextControllerNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
            EvercryptedTextControllerNotifier,
            EvercryptedTextController,
            EvercryptedTextController,
            EvercryptedTextController,
            (
              String, {
              String? initialText,
            })> {
  EvercryptedTextControllerNotifierFamily._()
      : super(
          retry: null,
          name: r'evercryptedTextControllerProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// A provider family that creates and manages EvercryptedTextController instances
  /// Automatically handles disposal when the provider is disposed
  /// Usage: ref.watch(evercryptedTextControllerProvider('key'))

  EvercryptedTextControllerNotifierProvider call(
    String key, {
    String? initialText,
  }) =>
      EvercryptedTextControllerNotifierProvider._(argument: (
        key,
        initialText: initialText,
      ), from: this);

  @override
  String toString() => r'evercryptedTextControllerProvider';
}

/// A provider family that creates and manages EvercryptedTextController instances
/// Automatically handles disposal when the provider is disposed
/// Usage: ref.watch(evercryptedTextControllerProvider('key'))

abstract class _$EvercryptedTextControllerNotifier
    extends $Notifier<EvercryptedTextController> {
  late final _$args = ref.$arg as (
    String, {
    String? initialText,
  });
  String get key => _$args.$1;
  String? get initialText => _$args.initialText;

  EvercryptedTextController build(
    String key, {
    String? initialText,
  });
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<EvercryptedTextController, EvercryptedTextController>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<EvercryptedTextController, EvercryptedTextController>,
        EvercryptedTextController,
        Object?,
        Object?>;
    element.handleCreate(
        ref,
        () => build(
              _$args.$1,
              initialText: _$args.initialText,
            ));
  }
}
