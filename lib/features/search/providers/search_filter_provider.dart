import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparrow/shared/tmdb_servicee.dart';

/// Singleton TMDB Service Provider
final tmdbServiceProvider = Provider<TmdbService>((ref) {
  return TmdbService();
});

/// Currently selected category filter (if any)

/// Sort/filter enum for the filter deck
enum SearchSortFilter {
  popularity('Popularity'),
  topRated('Top Rated'),
  releaseDate('Release Date');

  final String label;
  const SearchSortFilter(this.label);
}

class SearchFilterNotifier extends Notifier<SearchSortFilter> {
  @override
  SearchSortFilter build() => SearchSortFilter.popularity;

  void setFilter(SearchSortFilter filter) => state = filter;
  void reset() => state = SearchSortFilter.popularity;
}

final searchFilterProvider =
    NotifierProvider<SearchFilterNotifier, SearchSortFilter>(
      SearchFilterNotifier.new,
    );

/// Media type selector enum (Movies vs TV Shows)
enum SearchMediaType {
  movies('Movies'),
  tvShows('TV Shows');

  final String label;
  const SearchMediaType(this.label);
}

class SearchMediaTypeNotifier extends Notifier<SearchMediaType> {
  @override
  SearchMediaType build() => SearchMediaType.movies;

  void setType(SearchMediaType type) => state = type;
  void reset() => state = SearchMediaType.movies;
}

final searchMediaTypeProvider =
    NotifierProvider<SearchMediaTypeNotifier, SearchMediaType>(
      SearchMediaTypeNotifier.new,
    );
