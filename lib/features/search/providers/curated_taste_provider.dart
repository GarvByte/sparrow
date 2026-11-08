import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparrow/features/search/providers/search_filter_provider.dart';

class CuratedTasteNotifier extends AsyncNotifier<List> {
  @override
  Future<List> build() async {
    return fetchCurated();
  }

  Future<List> fetchCurated() async {
    final tmdbService = ref.read(tmdbServiceProvider);
    // Fetch popular/top rated selection
    final raw = await tmdbService.fetchMovies(
      'discover/movie?language=en-US&with_original_language=hi&page=2',
    );

    return raw;
  }
}

final curatedTasteProvider = AsyncNotifierProvider<CuratedTasteNotifier, List>(
  () => CuratedTasteNotifier(),
);
