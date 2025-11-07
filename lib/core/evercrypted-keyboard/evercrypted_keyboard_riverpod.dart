import 'package:evercrypted/main.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'evercrypted_keyboard_riverpod.g.dart';

/// State class to hold keyboard-related state
class KeyboardState {
  final Function(String)? onChange;
  final Function()? onClose;
  final Function()? onDone;
  final bool isMultiLine;
  final TextEditingController controller;

  const KeyboardState({
    this.onChange,
    this.onClose,
    this.onDone,
    this.isMultiLine = false,
    required this.controller,
  });

  // Create a new instance with updated values
  KeyboardState copyWith({
    Function(String)? onChange,
    Function()? onClose,
    Function()? onDone,
    bool? isMultiLine,
    TextEditingController? controller,
  }) {
    return KeyboardState(
      onChange: onChange ?? this.onChange,
      onClose: onClose ?? this.onClose,
      onDone: onDone ?? this.onDone,
      isMultiLine: isMultiLine ?? this.isMultiLine,
      controller: controller ?? this.controller,
    );
  }

  KeyboardState start({
    Function(String)? onChange,
    Function()? onClose,
    Function()? onDone,
    bool? isMultiLine,
    required TextEditingController controller,
  }) {
    return KeyboardState(
      controller: controller,
      onChange: onChange,
      onClose: onClose,
      onDone: onDone,
      isMultiLine: isMultiLine ?? false,
    );
  }
}

/// Notifier class to manage keyboard state changes
@Riverpod(keepAlive: true)
class KeyboardNotifier extends _$KeyboardNotifier {
  @override
  KeyboardState build() => KeyboardState(controller: TextEditingController());

  void close() {
    shouldShowKeyboard.value = false;
    state.onClose?.call();
  }

  void done() {
    state.onDone?.call();
  }

  void openKeyboard({
    Function(String)? onChange,
    Function()? onClose,
    Function()? onDone,
    bool? isMultiLine,
    required TextEditingController controller,
  }) {
    shouldShowKeyboard.value = true;
    state = state.start(
      onChange: onChange,
      onClose: onClose,
      onDone: onDone,
      isMultiLine: isMultiLine,
      controller: controller,
    );
  }

  void setKeyboardState({
    Function(String)? onChange,
    Function()? onClose,
    Function()? onDone,
    bool? isMultiLine,
    TextEditingController? controller,
  }) {
    state = state.copyWith(
      onChange: onChange,
      onClose: onClose,
      onDone: onDone,
      isMultiLine: isMultiLine,
      controller: controller,
    );
  }
}
