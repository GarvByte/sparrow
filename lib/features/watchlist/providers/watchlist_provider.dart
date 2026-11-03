import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/watchlist_item.dart';
import '../data/watchlist_repository.dart';

/// Provider for the singleton [WatchlistRepository].
final watchlistRepositoryProvider = Provider<WatchlistRepository>((ref) {
  return WatchlistRepository();
});

/// Riverpod [Notifier] exposing reactive state of the user's Watchlist.
class WatchlistNotifier extends Notifier<List<WatchlistItem>> {
  @override
  List<WatchlistItem> build() {
    final repository = ref.watch(watchlistRepositoryProvider);
    return repository.getAllItems();
  }

  /// Toggles an item in the Watchlist and refreshes the reactive state.
  Future<bool> toggle(WatchlistItem item) async {
    final repository = ref.read(watchlistRepositoryProvider);
    final isAdded = await repository.toggleItem(item);
    state = repository.getAllItems();
    return isAdded;
  }

  /// Adds an item to the Watchlist and refreshes the reactive state.
  Future<void> add(WatchlistItem item) async {
    final repository = ref.read(watchlistRepositoryProvider);
    await repository.addItem(item);
    state = repository.getAllItems();
  }

  /// Removes an item from the Watchlist by its type and ID.
  Future<void> remove(String mediaType, String id) async {
    final repository = ref.read(watchlistRepositoryProvider);
    await repository.removeItem(mediaType, id);
    state = repository.getAllItems();
  }

  /// Forces a sync with the persistent layer.
  void refresh() {
    final repository = ref.read(watchlistRepositoryProvider);
    state = repository.getAllItems();
  }
}

/// Primary reactive Watchlist provider for the application.
final watchlistProvider =
    NotifierProvider<WatchlistNotifier, List<WatchlistItem>>(
      WatchlistNotifier.new,
    );

/// Parameterized family provider checking if a title is watchlisted.
/// Re-evaluates instantly when [watchlistProvider] mutates.
final isWatchlistedProvider =
    Provider.family<bool, ({String mediaType, String id})>((ref, arg) {
      final items = ref.watch(watchlistProvider);
      final key = WatchlistItem.compositeKey(arg.mediaType, arg.id);
      return items.any((item) => item.key == key);
    });
