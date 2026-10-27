import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparrow/features/search/providers/search_filter_provider.dart';
import 'package:sparrow/features/search/providers/search_results_provider.dart';
import 'package:sparrow/features/search/screens/search_page.dart';
import 'package:sparrow/features/search/widgets/search_results_view.dart';
import 'package:sparrow/shared/tmdb_servicee.dart';

/// Mock TMDB Service that tracks all invocations and allows controlling completions
class _MockTmdbService extends TmdbService {
  final List<String> movieSearches = [];
  final List<String> tvSearches = [];
  Completer<List<dynamic>>? delayedCompleter;

  @override
  Future<List<dynamic>> searchMovies(String query, {int page = 1}) async {
    movieSearches.add(query);
    if (delayedCompleter != null) {
      return delayedCompleter!.future;
    }
    return [
      {
        'id': 100,
        'title': 'Movie for $query',
        'media_type': 'movie',
        'genre_ids': [28],
        'poster_path': '/poster.jpg',
      }
    ];
  }

  @override
  Future<List<dynamic>> searchTvShows(String query, {int page = 1}) async {
    tvSearches.add(query);
    if (delayedCompleter != null) {
      return delayedCompleter!.future;
    }
    return [
      {
        'id': 200,
        'name': 'TV Show for $query',
        'media_type': 'tv',
        'genre_ids': [18],
        'poster_path': '/poster.jpg',
      }
    ];
  }
}

void main() {
  group('Search Debounce & Network Reduction Tests', () {
    testWidgets(
      'Typing continuously resets debounce timer and makes only 1 request after pause',
      (tester) async {
        final mockService = _MockTmdbService();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              tmdbServiceProvider.overrideWithValue(mockService),
            ],
            child: const MaterialApp(
              home: SearchPage(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final textField = find.byType(TextField);
        expect(textField, findsOneWidget);

        // Simulate typing "doraemon" character by character at 300ms intervals
        final word = 'doraemon';
        for (int i = 1; i <= word.length; i++) {
          final partial = word.substring(0, i);
          await tester.enterText(textField, partial);
          await tester.pump(const Duration(milliseconds: 300));
          // During continuous typing, no search requests must be triggered
          expect(mockService.movieSearches, isEmpty,
              reason: 'Request triggered prematurely for intermediate "$partial"');
        }

        // Now pause typing for 1050ms (exceeding the 1000ms debounce threshold)
        await tester.pump(const Duration(milliseconds: 1050));
        await tester.pumpAndSettle();

        // Exactly ONE search request should have been dispatched for the full query
        expect(mockService.movieSearches.length, equals(1));
        expect(mockService.movieSearches.first, equals('doraemon'));

        // Results view is visible
        expect(find.byType(SearchResultsView), findsOneWidget);
      },
    );

    testWidgets(
      'Clearing query immediately restores discovery page without waiting for debounce',
      (tester) async {
        final mockService = _MockTmdbService();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              tmdbServiceProvider.overrideWithValue(mockService),
            ],
            child: const MaterialApp(
              home: SearchPage(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final textField = find.byType(TextField);

        // Type query and wait for results
        await tester.enterText(textField, 'Avatar');
        await tester.pump(const Duration(milliseconds: 1050));
        await tester.pumpAndSettle();

        expect(find.byType(SearchResultsView), findsOneWidget);

        // Delete text by entering empty string
        await tester.enterText(textField, '');
        await tester.pump();

        // Must immediately restore discover content without any debounce delay
        expect(find.byType(SearchResultsView), findsNothing);
        expect(find.text('Explore Categories'), findsOneWidget);
      },
    );

    testWidgets(
      'Submitting search via enter immediately triggers search without waiting for debounce',
      (tester) async {
        final mockService = _MockTmdbService();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              tmdbServiceProvider.overrideWithValue(mockService),
            ],
            child: const MaterialApp(
              home: SearchPage(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final textField = find.byType(TextField);

        // Enter query and immediately submit without waiting 1 second
        await tester.enterText(textField, 'Inception');
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pumpAndSettle();

        // Results should appear immediately
        expect(mockService.movieSearches.length, equals(1));
        expect(mockService.movieSearches.first, equals('Inception'));
        expect(find.byType(SearchResultsView), findsOneWidget);
      },
    );
  });

  group('Request Coordination & Stale Request Handling Tests', () {
    test('Older stale response cannot overwrite newer search results', () async {
      final mockService = _MockTmdbService();
      final container = ProviderContainer(
        overrides: [
          tmdbServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      // Start Request 1 with delayed completion
      final completer1 = Completer<List<dynamic>>();
      mockService.delayedCompleter = completer1;

      final future1 = container
          .read(searchResultsNotifier.notifier)
          .search(query: 'Batman');

      expect(container.read(searchResultsNotifier).isLoading, isTrue);

      // Start Request 2 with immediate completion
      mockService.delayedCompleter = null;
      await container
          .read(searchResultsNotifier.notifier)
          .search(query: 'Superman');

      // State is now data for Superman
      final stateAfterSuperman = container.read(searchResultsNotifier).value;
      expect(stateAfterSuperman, isNotNull);
      expect(stateAfterSuperman!.first['title'], equals('Movie for Superman'));

      // Now complete Request 1 (stale)
      completer1.complete([
        {'id': 999, 'title': 'Stale Batman'}
      ]);
      await future1;

      // State MUST remain Superman and not be overwritten by stale Batman
      final finalState = container.read(searchResultsNotifier).value;
      expect(finalState!.first['title'], equals('Movie for Superman'));
    });

    test('Deduplicates identical in-flight and loaded queries', () async {
      final mockService = _MockTmdbService();
      final container = ProviderContainer(
        overrides: [
          tmdbServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      final completer = Completer<List<dynamic>>();
      mockService.delayedCompleter = completer;

      // Trigger first search
      final future1 = container
          .read(searchResultsNotifier.notifier)
          .search(query: 'Dune');

      // Trigger duplicate search for exact same query while first is in-flight
      final future2 = container
          .read(searchResultsNotifier.notifier)
          .search(query: 'Dune');

      // Only ONE network request should have been made
      expect(mockService.movieSearches.length, equals(1));

      completer.complete([
        {'id': 1, 'title': 'Dune'}
      ]);
      await Future.wait([future1, future2]);

      // Trigger third search after data is already loaded
      await container
          .read(searchResultsNotifier.notifier)
          .search(query: 'Dune');

      // Still only ONE network request was made
      expect(mockService.movieSearches.length, equals(1));
    });

    test('Retry forces fresh search after error', () async {
      final mockService = _MockTmdbService();
      final container = ProviderContainer(
        overrides: [
          tmdbServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      // Simulate error on first attempt
      final errorCompleter = Completer<List<dynamic>>();
      mockService.delayedCompleter = errorCompleter;

      final searchFuture = container
          .read(searchResultsNotifier.notifier)
          .search(query: 'Interstellar');

      errorCompleter.completeError(Exception('Network timeout'));
      await searchFuture;

      expect(container.read(searchResultsNotifier).hasError, isTrue);

      // Retry with success
      mockService.delayedCompleter = null;
      await container.read(searchResultsNotifier.notifier).retry();

      expect(container.read(searchResultsNotifier).hasValue, isTrue);
      expect(container.read(searchResultsNotifier).hasError, isFalse);
      expect(mockService.movieSearches.length, equals(2));
    });

    test('Clear resets state and invalidates pending in-flight response', () async {
      final mockService = _MockTmdbService();
      final container = ProviderContainer(
        overrides: [
          tmdbServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      final completer = Completer<List<dynamic>>();
      mockService.delayedCompleter = completer;

      final searchFuture = container
          .read(searchResultsNotifier.notifier)
          .search(query: 'Gladiator');

      expect(container.read(searchResultsNotifier).isLoading, isTrue);

      // User clears search
      container.read(searchResultsNotifier.notifier).clear();
      expect(container.read(searchResultsNotifier).value, isEmpty);

      // In-flight request arrives after clear
      completer.complete([
        {'id': 5, 'title': 'Gladiator'}
      ]);
      await searchFuture;

      // Results must still be empty, stale response discarded
      expect(container.read(searchResultsNotifier).value, isEmpty);
    });

    test('Switching media type dispatches to correct TMDB endpoint', () async {
      final mockService = _MockTmdbService();
      final container = ProviderContainer(
        overrides: [
          tmdbServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      // Search Movies
      await container
          .read(searchResultsNotifier.notifier)
          .search(query: 'Breaking Bad', mediaType: SearchMediaType.movies);
      expect(mockService.movieSearches.length, equals(1));
      expect(mockService.tvSearches, isEmpty);

      // Search TV Shows
      await container
          .read(searchResultsNotifier.notifier)
          .search(query: 'Breaking Bad', mediaType: SearchMediaType.tvShows);
      expect(mockService.movieSearches.length, equals(1));
      expect(mockService.tvSearches.length, equals(1));
    });
  });
}
