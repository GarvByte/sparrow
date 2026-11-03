import 'package:hive/hive.dart';
import 'watchlist_item.dart';
import 'watchlist_storage.dart';

/// Repository abstracting persistence operations for user Watchlist entries.
///
/// Designed to interact directly with Hive local storage, while maintaining
/// an in-memory fallback for test harnesses that execute without Hive setup.
class WatchlistRepository {
  final Box<WatchlistItem>? _explicitBox;
  final Map<String, WatchlistItem> _memoryFallback = {};

  WatchlistRepository([this._explicitBox]);

  Box<WatchlistItem>? get _activeBox {
    if (_explicitBox != null && _explicitBox.isOpen) return _explicitBox;
    return WatchlistStorage.getBox();
  }

  /// Retrieves all persisted items, ordered by addition date descending.
  List<WatchlistItem> getAllItems() {
    final box = _activeBox;
    if (box != null && box.isOpen) {
      final list = box.values.toList();
      list.sort((a, b) {
        final aTime = a.addedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.addedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return list;
    }
    final list = _memoryFallback.values.toList();
    list.sort((a, b) {
      final aTime = a.addedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.addedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return list;
  }

  /// Determines whether a specific title is currently watchlisted.
  bool isWatchlisted(String mediaType, String id) {
    if (id.trim().isEmpty) return false;
    final key = WatchlistItem.compositeKey(mediaType, id);
    final box = _activeBox;
    if (box != null && box.isOpen) {
      return box.containsKey(key);
    }
    return _memoryFallback.containsKey(key);
  }

  /// Persists an item to Watchlist storage.
  Future<void> addItem(WatchlistItem item) async {
    final key = item.key;
    final box = _activeBox;
    if (box != null && box.isOpen) {
      await box.put(key, item);
    } else {
      _memoryFallback[key] = item;
    }
  }

  /// Removes an item from Watchlist storage.
  Future<void> removeItem(String mediaType, String id) async {
    final key = WatchlistItem.compositeKey(mediaType, id);
    final box = _activeBox;
    if (box != null && box.isOpen) {
      await box.delete(key);
    } else {
      _memoryFallback.remove(key);
    }
  }

  /// Toggles the membership of an item.
  /// Returns `true` if added, `false` if removed.
  Future<bool> toggleItem(WatchlistItem item) async {
    if (isWatchlisted(item.mediaType, item.id)) {
      await removeItem(item.mediaType, item.id);
      return false;
    } else {
      await addItem(item);
      return true;
    }
  }

  /// Clears all entries from storage.
  Future<void> clearAll() async {
    final box = _activeBox;
    if (box != null && box.isOpen) {
      await box.clear();
    }
    _memoryFallback.clear();
  }
}
