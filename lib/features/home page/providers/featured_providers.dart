import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/media_item.dart';
import '../data/mock_home_data.dart';

/// Abstract repository contract for fetching featured movies/anime.
///
/// Easily replaceable with a real API or backend service in the future.
abstract class FeaturedRepository {
  List<MediaItem> getFeaturedMedia();
}

/// Mock implementation providing curated featured titles.
class MockFeaturedRepository implements FeaturedRepository {
  @override
  List<MediaItem> getFeaturedMedia() {
    return MockHomeData.featuredHeroes;
  }
}

/// Provider for the featured repository instance.
final featuredRepositoryProvider = Provider<FeaturedRepository>((ref) {
  return MockFeaturedRepository();
});

/// Provider exposing the list of featured items.
final featuredListProvider = Provider<List<MediaItem>>((ref) {
  final repository = ref.watch(featuredRepositoryProvider);
  return repository.getFeaturedMedia();
});

/// Notifier for managing the selected featured movie index.
class SelectedFeaturedIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  @override
  set state(int value) => super.state = value;

  void setIndex(int index) => state = index;
}

/// Provider for the currently active/selected featured movie index.
/// Updated only when the user settles on a new page (not on every animation frame).
final selectedFeaturedIndexProvider =
    NotifierProvider<SelectedFeaturedIndexNotifier, int>(
  SelectedFeaturedIndexNotifier.new,
);

/// Derived provider exposing the currently selected MediaItem.
final selectedFeaturedMovieProvider = Provider<MediaItem?>((ref) {
  final items = ref.watch(featuredListProvider);
  final index = ref.watch(selectedFeaturedIndexProvider);
  if (items.isEmpty) return null;
  return items[index.clamp(0, items.length - 1)];
});
