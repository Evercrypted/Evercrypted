import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State class to hold keyboard-related state
class KeyboardState {
  final Function(String) onEvercryptedKeyboardTextChange;
  final Function() onClose;
  final Map<String, int> selection;
  final String? startingText;

  const KeyboardState({
    this.onEvercryptedKeyboardTextChange = _defaultTextChangeHandler,
    this.onClose = _defaultCloseHandler,
    this.selection = const {},
    this.startingText,
  });

  // Default handler that does nothing
  static void _defaultTextChangeHandler(String text) {}

  static void _defaultCloseHandler() {}

  // Create a new instance with updated values
  KeyboardState copyWith({
    Function(String)? onEvercryptedKeyboardTextChange,
    Function()? onClose,
    Map<String, int>? selection,
    String? startingText,
  }) {
    return KeyboardState(
      onEvercryptedKeyboardTextChange: onEvercryptedKeyboardTextChange ??
          this.onEvercryptedKeyboardTextChange,
      onClose: onClose ?? this.onClose,
      selection: selection ?? this.selection,
      startingText: startingText ?? this.startingText,
    );
  }
}

/// Notifier class to manage keyboard state changes
class KeyboardNotifier extends StateNotifier<KeyboardState> {
  KeyboardNotifier() : super(const KeyboardState());

  void setKeyboardState(
      {Function(String)? handler,
      String? startingText,
      Function()? onClose,
      Map<String, int>? selection}) {
    state = state.copyWith(
      onEvercryptedKeyboardTextChange: handler,
      onClose: onClose,
      startingText: startingText,
      selection: selection,
    );
  }
}

/// Provider for the keyboard state
final keyboardProvider =
    StateNotifierProvider<KeyboardNotifier, KeyboardState>((ref) {
  return KeyboardNotifier();
});
