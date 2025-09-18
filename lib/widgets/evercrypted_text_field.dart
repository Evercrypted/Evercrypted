import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/evercrypted-keyboard/evercrypted_keyboard_riverpod.dart';
import '../core/evercrypted-keyboard/evercrypted_text_controller.dart';

/// Global focus manager to track if any Evercrypted field has focus
class _EvercryptedFocusManager {
  static final Set<FocusNode> _activeFocusNodes = <FocusNode>{};
  static bool _closeScheduled = false;

  static void registerFocusNode(FocusNode node) {
    _activeFocusNodes.add(node);
  }

  static void unregisterFocusNode(FocusNode node) {
    _activeFocusNodes.remove(node);
  }

  static bool get hasAnyFocus => _activeFocusNodes.any((node) => node.hasFocus);

  static void scheduleKeyboardCloseIfNeeded(WidgetRef ref) {
    if (_closeScheduled) return;
    _closeScheduled = true;

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _closeScheduled = false;
      if (!hasAnyFocus) {
        ref.read(keyboardProvider.notifier).close();
      }
    });
  }
}

/// A TextField widget that automatically integrates with the Evercrypted keyboard
/// and handles cursor visibility without manual controller management
class EvercryptedTextField extends ConsumerStatefulWidget {
  final EvercryptedTextController controller;
  final InputDecoration? decoration;
  final TextStyle? style;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool obscureText;
  final String? hintText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final bool enabled;
  final bool readOnly;
  final bool isMultiLine;
  final Function()? onDone;
  final Function()? onClose;

  const EvercryptedTextField({
    super.key,
    required this.controller,
    this.decoration,
    this.style,
    this.maxLines,
    this.minLines,
    this.maxLength,
    this.obscureText = false,
    this.hintText,
    this.suffixIcon,
    this.prefixIcon,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.readOnly = false,
    this.isMultiLine = false,
    this.onDone,
    this.onClose,
  });

  @override
  ConsumerState<EvercryptedTextField> createState() =>
      _EvercryptedTextFieldState();
}

class _EvercryptedTextFieldState extends ConsumerState<EvercryptedTextField> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    // Connect the focus node to the controller
    widget.controller.setFocusNode(_focusNode);
    // Set the callback to open keyboard when focus is requested
    widget.controller.setOnFocusRequested(_openKeyboard);
    // Set the callback to close keyboard when unfocus is requested
    widget.controller.setOnUnfocusRequested(_closeKeyboard);

    // Register this focus node with the global manager
    _EvercryptedFocusManager.registerFocusNode(_focusNode);
    // Add focus listener to automatically hide keyboard when focus is lost
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      // Use the global focus manager to schedule keyboard close
      // This ensures only one close callback is scheduled per frame
      _EvercryptedFocusManager.scheduleKeyboardCloseIfNeeded(ref);
    }
  }

  void _openKeyboard() {
    // Trigger the same keyboard opening logic as onTap
    ref.read(keyboardProvider.notifier).openKeyboard(
          controller: widget.controller.textController,
          isMultiLine: widget.isMultiLine,
          onChange: (text) {
            // Trigger cursor visibility and call onChanged if provided
            widget.controller.ensureCursorVisible();
            widget.onChanged?.call(text);
          },
          onClose: widget.onClose,
          onDone: widget.onDone,
        );
  }

  void _closeKeyboard() {
    // Close the Evercrypted keyboard
    ref.read(keyboardProvider.notifier).close();
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _EvercryptedFocusManager.unregisterFocusNode(_focusNode);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller.textController,
      scrollController: widget.controller.scrollController,
      focusNode: _focusNode,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      minLines: widget.obscureText ? 1 : widget.minLines,
      maxLength: widget.maxLength,
      obscureText: widget.obscureText,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      style: widget.style,
      decoration: widget.decoration ??
          InputDecoration(
            hintText: widget.hintText,
            suffixIcon: widget.suffixIcon,
            prefixIcon: widget.prefixIcon,
          ),
      keyboardType: TextInputType.none, // Disable system keyboard
      onTap: _openKeyboard, // Use the same method as programmatic focus
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
    );
  }
}

/// A convenience widget that creates its own controller automatically
/// Perfect for simple use cases where you don't need to manage the controller manually
class AutoEvercryptedTextField extends ConsumerStatefulWidget {
  final String? initialText;
  final InputDecoration? decoration;
  final TextStyle? style;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool obscureText;
  final String? hintText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final bool enabled;
  final bool readOnly;
  final bool isMultiLine;
  final Function()? onDone;
  final Function()? onClose;

  const AutoEvercryptedTextField({
    super.key,
    this.initialText,
    this.decoration,
    this.style,
    this.maxLines,
    this.minLines,
    this.maxLength,
    this.obscureText = false,
    this.hintText,
    this.suffixIcon,
    this.prefixIcon,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.readOnly = false,
    this.isMultiLine = false,
    this.onDone,
    this.onClose,
  });

  @override
  ConsumerState<AutoEvercryptedTextField> createState() =>
      _AutoEvercryptedTextFieldState();
}

class _AutoEvercryptedTextFieldState
    extends ConsumerState<AutoEvercryptedTextField> {
  late EvercryptedTextController controller;

  @override
  void initState() {
    super.initState();
    controller = EvercryptedTextController(initialText: widget.initialText);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EvercryptedTextField(
      controller: controller,
      decoration: widget.decoration,
      style: widget.style,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      maxLength: widget.maxLength,
      obscureText: widget.obscureText,
      hintText: widget.hintText,
      suffixIcon: widget.suffixIcon,
      prefixIcon: widget.prefixIcon,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      isMultiLine: widget.isMultiLine,
      onDone: widget.onDone,
      onClose: widget.onClose,
    );
  }
}
