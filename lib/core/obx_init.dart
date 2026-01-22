import 'dart:async';
import 'package:evercrypted/core/entities/objectbox.dart';

/// Safe initialization wrapper for ObjectBox.
///
/// Provides both synchronous and async access to ObjectBox instance,
/// preventing LateInitializationError crashes on cold starts.
class ObxInit {
  static final Completer<ObjectBox> _obxCompleter = Completer<ObjectBox>();

  static ObjectBox? _obx;

  /// Synchronous access - throws if not ready.
  /// Use this when you're certain ObjectBox is initialized.
  static ObjectBox get obx {
    if (_obx == null) {
      throw StateError(
          'ObjectBox not initialized. Ensure ObxInit.initialize() was called in main().');
    }
    return _obx!;
  }

  /// Safe synchronous check - returns true if ObjectBox is ready.
  static bool get isReady => _obx != null;

  /// Safe async access - waits for initialization if not ready yet.
  static Future<ObjectBox> get obxAsync => _obxCompleter.future;

  /// Initialize ObjectBox. Call this once in main() before runApp().
  static Future<void> initialize() async {
    if (_obx != null) {
      // Already initialized
      return;
    }
    _obx = await ObjectBox.create();
    if (!_obxCompleter.isCompleted) {
      _obxCompleter.complete(_obx);
    }
  }
}
