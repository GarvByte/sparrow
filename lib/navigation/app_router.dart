import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sparrow/features/about_page/screens/movie_details_screen.dart';
import 'package:sparrow/features/home%20page/screen/home_page.dart';
import 'package:sparrow/features/search/screens/search_page.dart';
import 'package:sparrow/navigation/main_shell_scaffold.dart';

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
            ),
          ],
        ),
        // Branch 2: Anime Hub
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/anime',
              name: 'anime',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: TabPlaceholderPage(
                  title: 'Anime Hub',
                  icon: Icons.auto_awesome_rounded,
                ),
              ),
            ),
          ],
        ),
        // Branch 3: Profile & Settings
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              name: 'profile',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: TabPlaceholderPage(
                  title: 'Profile & Settings',
                  icon: Icons.person_rounded,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);
