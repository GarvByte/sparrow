import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'continue_watching_item.dart';

/// Centralized manager for the dedicated Hive box holding Continue Watching playback progress.
class ContinueWatchingStorage {
  static const String boxName = 'sparrow_continue_watching_box';
  static bool _initialized = false;

  /// Initializes Hive, registers the adapter, and opens the Continue Watching box.
  /// Called once during app startup before runApp.
  static Future<void> init() async {
    if (_initialized) return;
    try {
      await Hive.initFlutter();
      registerAdapter();
      await openBox();
      _initialized = true;
    } catch (e, stack) {
      debugPrint('ContinueWatchingStorage.init encountered an error: $e\n$stack');
    }
  }

  /// Safely registers the [ContinueWatchingItemAdapter] (typeId: 1) once.
  static void registerAdapter() {
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ContinueWatchingItemAdapter());
    }
  }

  /// Opens the [ContinueWatchingItem] box if not already open.
  static Future<Box<ContinueWatchingItem>> openBox() async {
    registerAdapter();
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<ContinueWatchingItem>(boxName);
    }
    return await Hive.openBox<ContinueWatchingItem>(boxName);
  }

  /// Returns the open [Box<ContinueWatchingItem>] synchronously, or null if unopened.
  static Box<ContinueWatchingItem>? getBox() {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<ContinueWatchingItem>(boxName);
    }
    return null;
  }
}
