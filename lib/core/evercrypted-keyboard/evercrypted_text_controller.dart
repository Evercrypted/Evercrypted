import 'package:flutter/material.dart';

/// A controller that manages both TextEditingController and ScrollController
/// for seamless integration with the Evercrypted keyboard
class EvercryptedTextController {
  final TextEditingController textController;
  final ScrollController scrollController;
  bool _disposed = false;

  EvercryptedTextController({
    String? initialText,
  })  : textController = TextEditingController(text: initialText),
        scrollController = ScrollController() {
    // Add listener to ensure cursor visibility when text changes
    textController.addListener(ensureCursorVisible);
  }

  /// Get the current text value
  String get text => textController.text;

  /// Set the text value
  set text(String value) => textController.text = value;

  /// Get the current selection
  TextSelection get selection => textController.selection;

  /// Set the selection
  set selection(TextSelection selection) => textController.selection = selection;

  /// Clear the text
  void clear() => textController.clear();

  /// Add listener to the text controller
  void addListener(VoidCallback listener) => textController.addListener(listener);

  /// Remove listener from the text controller
  void removeListener(VoidCallback listener) => textController.removeListener(listener);

  /// Check if the controller is disposed
  bool get isDisposed => _disposed;

  void ensureCursorVisible() {
    if (_disposed || !scrollController.hasClients) return;
    
    // Ensure cursor remains visible when text changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed || !scrollController.hasClients) return;
      
      // Small delay to ensure layout is complete
      Future.delayed(const Duration(milliseconds: 10), () {
        if (_disposed || !scrollController.hasClients) return;
        
        // Scroll to the end to keep the cursor visible
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      });
    });
  }

  /// Dispose both controllers and clean up listeners
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    
    textController.removeListener(ensureCursorVisible);
    textController.dispose();
    scrollController.dispose();
  }
}