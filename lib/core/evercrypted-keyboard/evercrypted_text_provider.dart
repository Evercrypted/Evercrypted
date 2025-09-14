import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'evercrypted_text_controller.dart';

/// A provider that creates and manages EvercryptedTextController instances
/// Automatically handles disposal when the provider is disposed
class EvercryptedTextControllerNotifier extends StateNotifier<EvercryptedTextController> {
  EvercryptedTextControllerNotifier({String? initialText})
      : super(EvercryptedTextController(initialText: initialText));

  @override
  void dispose() {
    state.dispose();
    super.dispose();
  }
}

/// Factory function to create text controller providers
/// Usage: final myTextControllerProvider = createEvercryptedTextProvider();
StateNotifierProvider<EvercryptedTextControllerNotifier, EvercryptedTextController>
    createEvercryptedTextProvider({String? initialText}) {
  return StateNotifierProvider<EvercryptedTextControllerNotifier, EvercryptedTextController>(
    (ref) => EvercryptedTextControllerNotifier(initialText: initialText),
  );
}

/// Alternative: Auto-dispose provider for temporary text fields
/// Usage: final tempTextProvider = createAutoDisposeEvercryptedTextProvider();
AutoDisposeStateNotifierProvider<EvercryptedTextControllerNotifier, EvercryptedTextController>
    createAutoDisposeEvercryptedTextProvider({String? initialText}) {
  return StateNotifierProvider.autoDispose<EvercryptedTextControllerNotifier, EvercryptedTextController>(
    (ref) => EvercryptedTextControllerNotifier(initialText: initialText),
  );
}