import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'evercrypted_text_controller.dart';

part 'evercrypted_text_provider.g.dart';

/// A provider family that creates and manages EvercryptedTextController instances
/// Automatically handles disposal when the provider is disposed
/// Usage: ref.watch(evercryptedTextControllerProvider('key'))
@riverpod
class EvercryptedTextControllerNotifier extends _$EvercryptedTextControllerNotifier {
  @override
  EvercryptedTextController build(String key, {String? initialText}) {
    final controller = EvercryptedTextController(initialText: initialText);
    ref.onDispose(() {
      controller.dispose();
    });
    return controller;
  }
}