import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sparrow/features/about_page/screens/movie_details_screen.dart';
import 'package:sparrow/features/anime%20hub/screens/anime_hub_page.dart';
import 'package:sparrow/features/home%20page/screen/home_page.dart';
import 'package:sparrow/features/player/models/playback_context.dart';
import 'package:sparrow/features/player/screens/player_page.dart';
import 'package:sparrow/features/search/data/category_item.dart';
import 'package:sparrow/features/search/screens/search_page.dart';
import 'package:sparrow/features/search/screens/tv_search_results_page.dart';
import 'package:sparrow/features/tv_show_details/screens/tv_show_details_screen.dart';
import 'package:sparrow/features/view_all/view_all_args.dart';
import 'package:sparrow/features/view_all/view_all_screen.dart';
import 'package:sparrow/features/watchlist/screen/watchlist_page.dart';
import 'package:sparrow/navigation/main_shell_scaffold.dart';
import 'package:sparrow/shared/media_item.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/movie-details',
      name: 'movie-details',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final movieData = state.extra;
        return MaterialPage(child: MovieDetailsScreen(movieData: movieData));
      },
    ),
    GoRoute(
      path: '/player',
      name: 'player',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final extra = state.extra;
        final PlaybackContext playbackContext;
        if (extra is PlaybackContext) {
          playbackContext = extra;
        } else if (extra is MediaItem) {
          playbackContext = PlaybackContext.fromMediaItem(extra);
        } else {
          playbackContext = PlaybackContext.fromMediaItem(
            const MediaItem(id: '0', title: 'Video', imageUrl: '', genres: []),
          );
        }

        return MaterialPage(
          child: PlayerPage(playbackContext: playbackContext),
        );
      },
    ),
    GoRoute(
      path: '/tv-show-details',
      name: 'tv-show-details',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final tvData = state.extra;
        return MaterialPage(child: TvShowDetailsScreen(tvData: tvData));
      },
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainShellScaffold(navigationShell: navigationShell);
      },
      branches: [
        // Branch 0: Home
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              name: 'home',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: HomePage()),
              routes: [
                GoRoute(
                  path: 'view-all',
                  name: 'home-view-all',
                  pageBuilder: (context, state) {
                    final args =
                        state.extra as ViewAllArgs? ??
                        const ViewAllArgs(
                          mediaType: 'movie',
                          categoryType: 'trending',
                          title: 'Trending Movies',
                        );
                    return MaterialPage(child: ViewAllScreen(args: args));
                  },
                ),
              ],
            ),
          ],
        ),
        // Branch 1: Search / Discover
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/search',
              name: 'search',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: SearchPage()),
              routes: [
                GoRoute(
                  path: 'results',
                  name: 'tv-search-results',
                  pageBuilder: (context, state) {
                    final extra = state.extra;
                    if (extra is CategoryItem) {
                      return MaterialPage(
                        child: TvSearchResultsPage(category: extra),
                      );
                    }
                    final query = extra is String ? extra : '';
                    return MaterialPage(
                      child: TvSearchResultsPage(query: query),
                    );
                  },
                ),
                GoRoute(
                  path: 'view-all',
                  name: 'search-view-all',
                  pageBuilder: (context, state) {
                    final args =
                        state.extra as ViewAllArgs? ??
                        const ViewAllArgs(
                          mediaType: 'movie',
                          categoryType: 'trending',
                          title: 'Trending Movies',
                        );
                    return MaterialPage(child: ViewAllScreen(args: args));
                  },
                ),
              ],
            ),
          ],
        ),
        // Branch 2: Anime Hub / TV Shows
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/anime',
              name: 'anime',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: AnimeHubPage()),
              routes: [
                GoRoute(
                  path: 'view-all',
                  name: 'tv-view-all',
                  pageBuilder: (context, state) {
                    final args =
                        state.extra as ViewAllArgs? ??
                        const ViewAllArgs(
                          mediaType: 'tv',
                          categoryType: 'trending',
                          title: 'Trending TV Shows',
                        );
                    return MaterialPage(child: ViewAllScreen(args: args));
                  },
                ),
              ],
            ),
          ],
        ),
        // Branch 3: Watchlist
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/watchlist',
              name: 'watchlist',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: WatchlistPage()),
            ),
          ],
        ),
      ],
    ),
  ],
);
