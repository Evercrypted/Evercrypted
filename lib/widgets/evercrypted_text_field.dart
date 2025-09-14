import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/evercrypted-keyboard/evercrypted_keyboard_riverpod.dart';
import '../core/evercrypted-keyboard/evercrypted_text_controller.dart';

/// A TextField widget that automatically integrates with the Evercrypted keyboard
/// and handles cursor visibility without manual controller management
class EvercryptedTextField extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    return TextField(
      controller: controller.textController,
      scrollController: controller.scrollController,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      obscureText: obscureText,
      enabled: enabled,
      readOnly: readOnly,
      style: style,
      decoration: decoration ??
          InputDecoration(
            hintText: hintText,
            suffixIcon: suffixIcon,
            prefixIcon: prefixIcon,
          ),
      keyboardType: TextInputType.none, // Disable system keyboard
      onTap: () {
        // Open Evercrypted keyboard when field is tapped
        ref.read(keyboardProvider.notifier).openKeyboard(
              controller: controller.textController,
              isMultiLine: isMultiLine,
              onChange: (text) {
                // Trigger cursor visibility and call onChanged if provided
                controller.ensureCursorVisible();
                onChanged?.call(text);
              },
              onClose: onClose,
              onDone: onDone,
            );
      },
      onChanged: onChanged,
      onSubmitted: onSubmitted,
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
  ConsumerState<AutoEvercryptedTextField> createState() => _AutoEvercryptedTextFieldState();
}

class _AutoEvercryptedTextFieldState extends ConsumerState<AutoEvercryptedTextField> {
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