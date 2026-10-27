import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final trendingTvShows = ref.watch(trendingShowProvider);

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

                  SizedBox(height: responsive.scale(14, min: 10, max: 20)),

                  // 2. Continue Watching Section
                  DpadRegion(
                    memoryKey: 'home/continueWatching',
                    leftEdge: DpadEdgeBehavior.leave,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(
                          leadingIcon: Icons.history_rounded,
                          title: 'Continue Watching',
                          actionText: 'See All',
                          onTrailingTap: () {},
                        ),
                        const SizedBox(height: 8),
                        _buildMediaCarouselSection(
                          asyncValue: trendingTvShows,
                          height: responsive.continueWatchingHeight,
                          onRetry: () => ref.refresh(trendingShowProvider),
                          carouselBuilder: (data) {
                            return HorizontalMediaCarousel(
                              height: responsive.continueWatchingHeight,
                              itemCount: data.length,
                              itemBuilder: (context, index) {
                                final movie = data[index];
                                final backdrop =
                                    movie['backdrop_path'] as String?;
                                final poster = movie['poster_path'] as String?;
                                final item = MediaItem(
                                  id: movie['id'].toString(),
                                  title: movie['title'] ?? 'Untitled',
                                  rating: (movie['vote_average'] as num?)
                                      ?.toDouble(),
                                  ratingCount: movie['vote_count']?.toString(),
                                  imageUrl:
                                      backdrop != null && backdrop.isNotEmpty
                                      ? imageBaseUrl + backdrop
                                      : (poster != null && poster.isNotEmpty
                                            ? imageBaseUrl + poster
                                            : ''),
                                  genres: movie['genre'] ?? [],
                                  isAdult: movie['adult'] as bool? ?? false,
                                  overview: movie['overview'] as String?,
                                  releaseDate: movie['release_date'] as String?,
                                  backdropUrl:
                                      backdrop != null && backdrop.isNotEmpty
                                      ? imageBaseUrl2 + backdrop
                                      : null,
                                );
                                return FocusablePosterCard(
                                  onSelected: () =>
                                      openMovieDetails(context, item),
                                  child: ContinueWatchingCard(
                                    item: item,
                                    width: responsive.continueWatchingWidth,
                                    onTap: () =>
                                        openMovieDetails(context, item),
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
                                final poster = movie['poster_path'] as String?;
                                final item = MediaItem(
                                  id: movie['id'].toString(),
                                  title: movie['title'] ?? 'Untitled',
                                  rating: (movie['vote_average'] as num?)
                                      ?.toDouble(),
                                  ratingCount: movie['vote_count']?.toString(),
                                  imageUrl: poster != null && poster.isNotEmpty
                                      ? imageBaseUrl + poster
                                      : (backdrop != null && backdrop.isNotEmpty
                                            ? imageBaseUrl + backdrop
                                            : ''),
                                  genres: movie['genre'] ?? [],
                                  isAdult: movie['adult'] as bool? ?? false,
                                  overview: movie['overview'] as String?,
                                  releaseDate: movie['release_date'] as String?,
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
                                final poster = movie['poster_path'] as String?;
                                final item = MediaItem(
                                  id: movie['id'].toString(),
                                  title: movie['title'] ?? 'Untitled',
                                  rating: (movie['vote_average'] as num?)
                                      ?.toDouble(),
                                  ratingCount: movie['vote_count']?.toString(),
                                  imageUrl: poster != null && poster.isNotEmpty
                                      ? imageBaseUrl + poster
                                      : (backdrop != null && backdrop.isNotEmpty
                                            ? imageBaseUrl + backdrop
                                            : ''),
                                  genres: movie['genre'] ?? [],
                                  isAdult: movie['adult'] as bool? ?? false,
                                  overview: movie['overview'] as String?,
                                  releaseDate: movie['release_date'] as String?,
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
                                final poster = movie['poster_path'] as String?;
                                final item = MediaItem(
                                  id: movie['id'].toString(),
                                  title: movie['title'] ?? 'Untitled',
                                  rating: (movie['vote_average'] as num?)
                                      ?.toDouble(),
                                  ratingCount: movie['vote_count']?.toString(),
                                  imageUrl: poster != null && poster.isNotEmpty
                                      ? imageBaseUrl + poster
                                      : (backdrop != null && backdrop.isNotEmpty
                                            ? imageBaseUrl + backdrop
                                            : ''),
                                  genres: movie['genre'] ?? [],
                                  isAdult: movie['adult'] as bool? ?? false,
                                  overview: movie['overview'] as String?,
                                  releaseDate: movie['release_date'] as String?,
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

                  // 6. Genre-Based Movie Sections (Self-contained ConsumerWidgets to prevent full-page rebuilds)
                  ..._buildGenreSections(context, ref, responsive),
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
