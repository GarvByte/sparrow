import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'watchlist_item.dart';

/// Centralized manager for the Hive local database box holding saved Watchlist items.
class WatchlistStorage {
  static const String boxName = 'sparrow_watchlist_box';
  static bool _initialized = false;

  /// Initializes Hive, registers the adapter, and opens the Watchlist box.
  /// Called once during app startup before runApp.
  static Future<void> init() async {
    if (_initialized) return;
    try {
      await Hive.initFlutter();
      registerAdapter();
      await openBox();
      _initialized = true;
    } catch (e, stack) {
      debugPrint('WatchlistStorage.init encountered an error: $e\n$stack');
    }
  }

  /// Safely registers the [WatchlistItemAdapter] once.
  static void registerAdapter() {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(WatchlistItemAdapter());
    }
  }

  /// Opens the [WatchlistItem] box if not already open.
  static Future<Box<WatchlistItem>> openBox() async {
    registerAdapter();
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<WatchlistItem>(boxName);
    }
    return await Hive.openBox<WatchlistItem>(boxName);
  }

  /// Returns the open [Box<WatchlistItem>] synchronously, or null if unopened.
  static Box<WatchlistItem>? getBox() {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<WatchlistItem>(boxName);
    }
    return null;
  }
}
