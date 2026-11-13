import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sparrow/features/continue_watching/data/continue_watching_item.dart';
import 'package:sparrow/features/continue_watching/providers/continue_watching_provider.dart';
import 'package:sparrow/features/player/models/playback_context.dart';
import 'package:sparrow/features/player/services/key_config_manager.dart';
import 'package:sparrow/features/player/services/key_config_models.dart';
import 'package:sparrow/navigation/dpad_navigation.dart';
import 'package:sparrow/shared/media_item.dart';
import 'package:sparrow/shared/navigation/movie_navigation.dart';
import 'package:sparrow/features/home%20page/providers/movieProvider.dart';
import 'package:sparrow/shared/tmdb_base_url.dart';
import '../../../shared/responsive_utils.dart';
import '../../../theme/color_palette.dart';
import '../widgets/continue_watching_card.dart';
import '../widgets/featured_hero_card.dart';
import '../widgets/horizontal_media_carousel.dart';
import '../widgets/portrait_poster_card.dart';
import 'package:sparrow/features/view_all/view_all_args.dart';
import 'package:sparrow/shared/genre_providers.dart';
import 'package:sparrow/shared/navigation/view_all_navigation.dart';
import '../widgets/section_header.dart';
import '../widgets/sparrow_header.dart';
import '../../../shared/scroll_aware_header.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _headerController = ScrollAwareHeaderController();

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  Widget _buildMediaCarouselSection({
    required AsyncValue<List<dynamic>> asyncValue,
    required double height,
    required VoidCallback onRetry,
    required Widget Function(List<dynamic> data) carouselBuilder,
  }) {
    if (asyncValue.hasValue &&
        asyncValue.value != null &&
        asyncValue.value!.isNotEmpty) {
      return carouselBuilder(asyncValue.value!);
    }

    if (asyncValue.isLoading) {
      return SizedBox(
        height: height,
        child: const Center(
          child: CircularProgressIndicator(
            color: ColorPalette.primaryGreen,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    if (asyncValue.hasError) {
      return SizedBox(
        height: 70,
        child: Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: 18,
                color: ColorPalette.textMuted,
              ),
              const Text(
                'Failed to load section',
                style: TextStyle(color: ColorPalette.textMuted, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              TextButton(
                onPressed: onRetry,
                child: const Text(
                  'Retry',
                  style: TextStyle(color: ColorPalette.primaryGreen),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final topPadding = responsive.padding.top;
    final headerHeight = responsive.headerHeight;
    final trendingNowMovies = ref.watch(trendingNowProvider);
    final popularMovies = ref.watch(popularMoviesProvider);
    final topRatedMovies = ref.watch(topRatedMoviesProvider);
    final discoverHindiMovies = ref.watch(discoverHindiMoviesProvider);
    final discoverIndianMovies = ref.watch(discoverIndianMoviesProvider);

    return Scaffold(
      backgroundColor: ColorPalette.backgroundBlack,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [ColorPalette.backgroundBlack, ColorPalette.gradientEnd],
          ),
        ),
        child: Stack(
          children: [
            // Scrollable Home Content Body
            NotificationListener<ScrollNotification>(
              onNotification: _headerController.handleScrollNotification,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  top: topPadding + headerHeight + 6,
                  bottom: 110, // Buffer to clear floating bottom nav
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Layered Overlapping Featured Hero Carousel (17:16 poster, Riverpod-driven, TV DPAD support)
                    FeaturedHeroSection(
                      onWatchNow: (item) => openMovieDetails(context, item),
                    ),

                    // 2. Continue Watching Section (Reactive local Hive storage, hidden if empty)
                    _buildContinueWatchingSection(context, responsive),

                    // 3. Trending Now Section
                    DpadRegion(
                      memoryKey: 'home/trendingNow',
                      leftEdge: DpadEdgeBehavior.leave,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(
                            overline: 'TOP PICKS TODAY',
                            title: 'Trending Now',
                            actionText: "View all",
                            onTrailingTap: () {
                              openViewAll(
                                context,
                                const ViewAllArgs(
                                  mediaType: 'movie',
                                  categoryType: 'trending',
                                  title: 'Trending Movies',
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          _buildMediaCarouselSection(
                            asyncValue: trendingNowMovies,
                            height: responsive.trendingPosterHeight,
                            onRetry: () => ref.refresh(trendingNowProvider),
                            carouselBuilder: (data) {
                              return HorizontalMediaCarousel(
                                height: responsive.trendingPosterHeight,
                                itemCount: data.length,
                                itemBuilder: (context, index) {
                                  final movie = data[index];
                                  final backdrop =
                                      movie['backdrop_path'] as String?;
                                  final poster =
                                      movie['poster_path'] as String?;
                                  final item = MediaItem(
                                    id: movie['id'].toString(),
                                    title: movie['title'] ?? 'Untitled',
                                    rating: (movie['vote_average'] as num?)
                                        ?.toDouble(),
                                    ratingCount: movie['vote_count']
                                        ?.toString(),
                                    imageUrl:
                                        poster != null && poster.isNotEmpty
                                        ? imageBaseUrl + poster
                                        : (backdrop != null &&
                                                  backdrop.isNotEmpty
                                              ? imageBaseUrl + backdrop
                                              : ''),
                                    genres: movie['genre'] ?? [],
                                    isAdult: movie['adult'] as bool? ?? false,
                                    overview: movie['overview'] as String?,
                                    releaseDate:
                                        movie['release_date'] as String?,
                                    backdropUrl:
                                        backdrop != null && backdrop.isNotEmpty
                                        ? imageBaseUrl2 + backdrop
                                        : null,
                                  );
                                  return Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: FocusablePosterCard(
                                      onSelected: () =>
                                          openMovieDetails(context, item),
                                      child: PortraitPosterCard(
                                        item: item,
                                        width: responsive.trendingPosterWidth,
                                        trending: true,
                                        index: index,
                                        onTap: () =>
                                            openMovieDetails(context, item),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: responsive.scale(18, min: 12, max: 24)),

                    //popular in hindi section
                    DpadRegion(
                      memoryKey: 'home/discoverHindiMovies',
                      leftEdge: DpadEdgeBehavior.leave,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(
                            leadingIcon: Icons.auto_awesome_rounded,
                            title: 'Best in Hindi',
                            actionText: 'View all',
                            onTrailingTap: () {
                              openViewAll(
                                context,
                                const ViewAllArgs(
                                  mediaType: 'movie',
                                  categoryType: 'discoverHindiMovies',
                                  title: 'Best in Hindi',
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          _buildMediaCarouselSection(
                            asyncValue: discoverHindiMovies,
                            height: responsive.animePosterHeight,
                            onRetry: () =>
                                ref.refresh(discoverHindiMoviesProvider),
                            carouselBuilder: (data) {
                              return HorizontalMediaCarousel(
                                height: responsive.animePosterHeight,
                                itemCount: data.length,
                                itemBuilder: (context, index) {
                                  final movie = data[index];
                                  final backdrop =
                                      movie['backdrop_path'] as String?;
                                  final poster =
                                      movie['poster_path'] as String?;
                                  final item = MediaItem(
                                    id: movie['id'].toString(),
                                    title: movie['title'] ?? 'Untitled',
                                    rating: (movie['vote_average'] as num?)
                                        ?.toDouble(),
                                    ratingCount: movie['vote_count']
                                        ?.toString(),
                                    imageUrl:
                                        poster != null && poster.isNotEmpty
                                        ? imageBaseUrl + poster
                                        : (backdrop != null &&
                                                  backdrop.isNotEmpty
                                              ? imageBaseUrl + backdrop
                                              : ''),
                                    genres: movie['genre'] ?? [],
                                    isAdult: movie['adult'] as bool? ?? false,
                                    overview: movie['overview'] as String?,
                                    releaseDate:
                                        movie['release_date'] as String?,
                                    backdropUrl:
                                        backdrop != null && backdrop.isNotEmpty
                                        ? imageBaseUrl2 + backdrop
                                        : null,
                                  );
                                  return Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: FocusablePosterCard(
                                      onSelected: () =>
                                          openMovieDetails(context, item),
                                      child: PortraitPosterCard(
                                        item: item,
                                        width: responsive.animePosterWidth,
                                        onTap: () =>
                                            openMovieDetails(context, item),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                   

                    // 4. Popular Movie Section
                    DpadRegion(
                      memoryKey: 'home/popularMovies',
                      leftEdge: DpadEdgeBehavior.leave,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(
                            leadingIcon: Icons.auto_awesome_rounded,
                            title: 'Popular Movies',
                            actionText: 'View all',
                            onTrailingTap: () {
                              openViewAll(
                                context,
                                const ViewAllArgs(
                                  mediaType: 'movie',
                                  categoryType: 'popular',
                                  title: 'Popular Movies',
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          _buildMediaCarouselSection(
                            asyncValue: popularMovies,
                            height: responsive.animePosterHeight,
                            onRetry: () => ref.refresh(popularMoviesProvider),
                            carouselBuilder: (data) {
                              return HorizontalMediaCarousel(
                                height: responsive.animePosterHeight,
                                itemCount: data.length,
                                itemBuilder: (context, index) {
                                  final movie = data[index];
                                  final backdrop =
                                      movie['backdrop_path'] as String?;
                                  final poster =
                                      movie['poster_path'] as String?;
                                  final item = MediaItem(
                                    id: movie['id'].toString(),
                                    title: movie['title'] ?? 'Untitled',
                                    rating: (movie['vote_average'] as num?)
                                        ?.toDouble(),
                                    ratingCount: movie['vote_count']
                                        ?.toString(),
                                    imageUrl:
                                        poster != null && poster.isNotEmpty
                                        ? imageBaseUrl + poster
                                        : (backdrop != null &&
                                                  backdrop.isNotEmpty
                                              ? imageBaseUrl + backdrop
                                              : ''),
                                    genres: movie['genre'] ?? [],
                                    isAdult: movie['adult'] as bool? ?? false,
                                    overview: movie['overview'] as String?,
                                    releaseDate:
                                        movie['release_date'] as String?,
                                    backdropUrl:
                                        backdrop != null && backdrop.isNotEmpty
                                        ? imageBaseUrl2 + backdrop
                                        : null,
                                  );
                                  return Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: FocusablePosterCard(
                                      onSelected: () =>
                                          openMovieDetails(context, item),
                                      child: PortraitPosterCard(
                                        item: item,
                                        width: responsive.animePosterWidth,
                                        onTap: () =>
                                            openMovieDetails(context, item),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: responsive.scale(18, min: 12, max: 24)),

                    // 5. Blockbusters & Classics Section
                    DpadRegion(
                      memoryKey: 'home/topRated',
                      leftEdge: DpadEdgeBehavior.leave,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(
                            title: 'Blockbusters & Classics',
                            actionText: 'View all',
                            onTrailingTap: () {
                              openViewAll(
                                context,
                                const ViewAllArgs(
                                  mediaType: 'movie',
                                  categoryType: 'top_rated',
                                  title: 'Blockbusters & Classics',
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          _buildMediaCarouselSection(
                            asyncValue: topRatedMovies,
                            height: responsive.animePosterHeight,
                            onRetry: () => ref.refresh(topRatedMoviesProvider),
                            carouselBuilder: (data) {
                              return HorizontalMediaCarousel(
                                height: responsive.animePosterHeight,
                                itemCount: data.length,
                                itemBuilder: (context, index) {
                                  final movie = data[index];
                                  final backdrop =
                                      movie['backdrop_path'] as String?;
                                  final poster =
                                      movie['poster_path'] as String?;
                                  final item = MediaItem(
                                    id: movie['id'].toString(),
                                    title: movie['title'] ?? 'Untitled',
                                    rating: (movie['vote_average'] as num?)
                                        ?.toDouble(),
                                    ratingCount: movie['vote_count']
                                        ?.toString(),
                                    imageUrl:
                                        poster != null && poster.isNotEmpty
                                        ? imageBaseUrl + poster
                                        : (backdrop != null &&
                                                  backdrop.isNotEmpty
                                              ? imageBaseUrl + backdrop
                                              : ''),
                                    genres: movie['genre'] ?? [],
                                    isAdult: movie['adult'] as bool? ?? false,
                                    overview: movie['overview'] as String?,
                                    releaseDate:
                                        movie['release_date'] as String?,
                                    backdropUrl:
                                        backdrop != null && backdrop.isNotEmpty
                                        ? imageBaseUrl2 + backdrop
                                        : null,
                                  );
                                  return Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: FocusablePosterCard(
                                      onSelected: () =>
                                          openMovieDetails(context, item),
                                      child: PortraitPosterCard(
                                        item: item,
                                        width: responsive.animePosterWidth,
                                        onTap: () =>
                                            openMovieDetails(context, item),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                     DpadRegion(
                      memoryKey: 'home/discoverIndianMovies',
                      leftEdge: DpadEdgeBehavior.leave,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(
                            title: 'Indian Masala and Tadka',
                            actionText: 'View all',
                            onTrailingTap: () {
                              openViewAll(
                                context,
                                const ViewAllArgs(
                                  mediaType: 'movie',
                                  categoryType: 'discoverIndianMovies',
                                  title: 'Indian Tadka and Masala',
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          _buildMediaCarouselSection(
                            asyncValue: discoverIndianMovies,
                            height: responsive.animePosterHeight,
                            onRetry: () =>
                                ref.refresh(discoverIndianMoviesProvider),
                            carouselBuilder: (data) {
                              return HorizontalMediaCarousel(
                                height: responsive.animePosterHeight,
                                itemCount: data.length,
                                itemBuilder: (context, index) {
                                  final movie = data[index];
                                  final backdrop =
                                      movie['backdrop_path'] as String?;
                                  final poster =
                                      movie['poster_path'] as String?;
                                  final item = MediaItem(
                                    id: movie['id'].toString(),
                                    title: movie['title'] ?? 'Untitled',
                                    rating: (movie['vote_average'] as num?)
                                        ?.toDouble(),
                                    ratingCount: movie['vote_count']
                                        ?.toString(),
                                    imageUrl:
                                        poster != null && poster.isNotEmpty
                                        ? imageBaseUrl + poster
                                        : (backdrop != null &&
                                                  backdrop.isNotEmpty
                                              ? imageBaseUrl + backdrop
                                              : ''),
                                    genres: movie['genre'] ?? [],
                                    isAdult: movie['adult'] as bool? ?? false,
                                    overview: movie['overview'] as String?,
                                    releaseDate:
                                        movie['release_date'] as String?,
                                    backdropUrl:
                                        backdrop != null && backdrop.isNotEmpty
                                        ? imageBaseUrl2 + backdrop
                                        : null,
                                  );
                                  return Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: FocusablePosterCard(
                                      onSelected: () =>
                                          openMovieDetails(context, item),
                                      child: PortraitPosterCard(
                                        item: item,
                                        width: responsive.animePosterWidth,
                                        onTap: () =>
                                            openMovieDetails(context, item),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // 6. Genre-Based Movie Sections (Self-contained ConsumerWidgets to prevent full-page rebuilds)
                    ..._buildGenreSections(context, ref, responsive),

                    // Force refresh control after all sections end (in the center, D-pad navigable)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: _HomeKeyRefreshButton(responsive: responsive),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Pinned Frosted Sparrow Header at Top with Scroll Awareness
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ScrollAwareHeader(
                controller: _headerController,
                child: const SparrowHeader(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueWatchingSection(
    BuildContext context,
    SparrowResponsive responsive,
  ) {
    final continueWatchingItems = ref.watch(continueWatchingProvider);
    if (continueWatchingItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: responsive.scale(14, min: 10, max: 20)),
        DpadRegion(
          memoryKey: 'home/continueWatching',
          leftEdge: DpadEdgeBehavior.leave,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                leadingIcon: Icons.history_rounded,
                title: 'Continue Watching',
              ),
              const SizedBox(height: 8),
              HorizontalMediaCarousel(
                height: responsive.continueWatchingHeight,
                itemCount: continueWatchingItems.length,
                itemBuilder: (context, index) {
                  final entry = continueWatchingItems[index];
                  final item = entry.toMediaItem();
                  return ContinueWatchingCard(
                    item: item,
                    width: responsive.continueWatchingWidth,
                    onTap: () => _openContinueWatchingItem(context, entry),
                    onRemove: () {
                      ref
                          .read(continueWatchingProvider.notifier)
                          .remove(entry.key);
                    },
                  );
                },
              ),
            ],
          ),
        ),
        SizedBox(height: responsive.scale(18, min: 12, max: 24)),
      ],
    );
  }

  void _openContinueWatchingItem(
    BuildContext context,
    ContinueWatchingItem entry,
  ) {
    final playbackContext = entry.isTvShow
        ? PlaybackContext.tv(
            item: entry.toMediaItem(),
            season: entry.season,
            episode: entry.episode,
            episodeTitle: entry.episodeTitle,
          )
        : PlaybackContext.movie(item: entry.toMediaItem());
    context.push('/player', extra: playbackContext);
  }

  List<Widget> _buildGenreSections(
    BuildContext context,
    WidgetRef ref,
    SparrowResponsive responsive,
  ) {
    final genresAsync = ref.watch(movieGenresProvider);
    const selectedGenreIds = [
      28,
      35,
      53,
      878,
      27,
      99
    ]; // Action, Comedy, Thriller, Sci-Fi, Horror

    final allGenres = genresAsync.value ?? fallbackMovieGenres;
    final genresToShow = allGenres
        .where((g) => selectedGenreIds.contains(g.id))
        .toList();

    return genresToShow
        .map((genre) => _HomeGenreSection(genre: genre, responsive: responsive))
        .toList();
  }
}

/// Independent consumer section for each movie genre. Prevents full HomePage rebuilds
/// when individual genre network requests complete or refresh.
class _HomeGenreSection extends ConsumerWidget {
  final TmdbGenre genre;
  final SparrowResponsive responsive;

  const _HomeGenreSection({required this.genre, required this.responsive});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moviesAsync = ref.watch(movieByGenreProvider(genre.id));

    Widget content;
    if (moviesAsync.hasValue &&
        moviesAsync.value != null &&
        moviesAsync.value!.isNotEmpty) {
      final items = moviesAsync.value!;
      content = HorizontalMediaCarousel(
        height: responsive.animePosterHeight,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: FocusablePosterCard(
              onSelected: () => openMovieDetails(context, item),
              child: PortraitPosterCard(
                item: item,
                width: responsive.animePosterWidth,
                onTap: () => openMovieDetails(context, item),
              ),
            ),
          );
        },
      );
    } else if (moviesAsync.isLoading) {
      content = SizedBox(
        height: responsive.animePosterHeight,
        child: const Center(
          child: CircularProgressIndicator(
            color: ColorPalette.primaryGreen,
            strokeWidth: 2.5,
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: responsive.scale(18, min: 12, max: 24)),
        DpadRegion(
          memoryKey: 'home/genre_${genre.id}',
          leftEdge: DpadEdgeBehavior.leave,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: genre.name,
                actionText: 'View all',
                onTrailingTap: () {
                  openViewAll(
                    context,
                    ViewAllArgs(
                      mediaType: 'movie',
                      categoryType: 'genre',
                      genreId: genre.id,
                      title: '${genre.name} Movies',
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              content,
            ],
          ),
        ),
      ],
    );
  }
}

class _HomeKeyRefreshButton extends StatefulWidget {
  final SparrowResponsive responsive;

  const _HomeKeyRefreshButton({required this.responsive});

  @override
  State<_HomeKeyRefreshButton> createState() => _HomeKeyRefreshButtonState();
}

class _HomeKeyRefreshButtonState extends State<_HomeKeyRefreshButton> {
  bool _isRefreshing = false;

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);

    try {
      final result = await KeyConfigManager.instance.forceRefresh();
      if (!mounted) return;

      final String message;
      switch (result) {
        case KeyRefreshResult.updated:
          final version = KeyConfigManager.instance.activeConfig?.version;
          message = version != null
              ? 'Encryption key updated to version $version'
              : 'Encryption key updated successfully';
          break;
        case KeyRefreshResult.noChange:
          message = 'Encryption keys are up to date';
          break;
        case KeyRefreshResult.failed:
          message = 'Failed to refresh encryption keys. Please check connection.';
          break;
      }

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          backgroundColor: ColorPalette.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: ColorPalette.ghostBorder, width: 0.5),
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Failed to refresh encryption keys',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            backgroundColor: ColorPalette.surfaceContainer,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttonSize = widget.responsive.scale(38, min: 34, max: 42);

    return DpadRegion(
      memoryKey: 'home/key_refresh',
      child: TvFocusable(
        onSelect: _handleRefresh,
        borderRadius: BorderRadius.circular(buttonSize / 2),
        child: InkWell(
          onTap: _handleRefresh,
          borderRadius: BorderRadius.circular(buttonSize / 2),
          child: Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              color: ColorPalette.surfaceContainer.withValues(alpha: 0.6),
              shape: BoxShape.circle,
              border: Border.all(color: ColorPalette.ghostBorder, width: 0.8),
            ),
            child: Center(
              child: _isRefreshing
                  ? SizedBox(
                      width: buttonSize * 0.45,
                      height: buttonSize * 0.45,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.0,
                        color: ColorPalette.primaryGreen,
                      ),
                    )
                  : Icon(
                      Icons.refresh_rounded,
                      size: (buttonSize * 0.52).clamp(16.0, 22.0),
                      color: ColorPalette.fontWhite,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
