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

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
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
            SingleChildScrollView(
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
                        trendingTvShows.when(
                          data: (data) {
                            return HorizontalMediaCarousel(
                              height: responsive.continueWatchingHeight,
                              itemCount: data.length,
                              itemBuilder: (context, index) {
                                final movie = data[index];
                                final backdrop = movie['backdrop_path'] as String?;
                                final poster = movie['poster_path'] as String?;
                                final item = MediaItem(
                                  id: movie['id'].toString(),
                                  title: movie['title'] ?? 'Untitled',
                                  rating: (movie['vote_average'] as num?)?.toDouble(),
                                  ratingCount: movie['vote_count']?.toString(),
                                  imageUrl: backdrop != null && backdrop.isNotEmpty
                                      ? imageBaseUrl + backdrop
                                      : (poster != null && poster.isNotEmpty
                                            ? imageBaseUrl + poster
                                            : ''),
                                  genres: movie['genre'] ?? [],
                                  isAdult: movie['adult'] as bool? ?? false,
                                  overview: movie['overview'] as String?,
                                  releaseDate: movie['release_date'] as String?,
                                  backdropUrl: backdrop != null && backdrop.isNotEmpty
                                      ? imageBaseUrl2 + backdrop
                                      : null,
                                );
                                return FocusablePosterCard(
                                  onSelected: () => openMovieDetails(context, item),
                                  child: ContinueWatchingCard(
                                    item: item,
                                    width: responsive.continueWatchingWidth,
                                    onTap: () => openMovieDetails(context, item),
                                  ),
                                );
                              },
                            );
                          },
                          error: (error, stackTrace) => Text("Error: $error"),
                          loading: () => const CircularProgressIndicator(
                            color: ColorPalette.primaryGreen,
                          ),
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
                        trendingNowMovies.when(
                          data: (data) {
                            return HorizontalMediaCarousel(
                              height: responsive.trendingPosterHeight,
                              itemCount: data.length,
                              itemBuilder: (context, index) {
                                final movie = data[index];
                                final backdrop = movie['backdrop_path'] as String?;
                                final poster = movie['poster_path'] as String?;
                                final item = MediaItem(
                                  id: movie['id'].toString(),
                                  title: movie['title'] ?? 'Untitled',
                                  rating: (movie['vote_average'] as num?)?.toDouble(),
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
                                  backdropUrl: backdrop != null && backdrop.isNotEmpty
                                      ? imageBaseUrl2 + backdrop
                                      : null,
                                );
                                return Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: FocusablePosterCard(
                                    onSelected: () => openMovieDetails(context, item),
                                    child: PortraitPosterCard(
                                      item: item,
                                      width: responsive.trendingPosterWidth,
                                      trending: true,
                                      index: index,
                                      onTap: () => openMovieDetails(context, item),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          error: (error, stackTrace) => Text("Error $error"),
                          loading: () => const CircularProgressIndicator(
                            color: ColorPalette.primaryGreen,
                          ),
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
                        popularMovies.when(
                          data: (data) {
                            return HorizontalMediaCarousel(
                              height: responsive.animePosterHeight,
                              itemCount: data.length,
                              itemBuilder: (context, index) {
                                final movie = data[index];
                                final backdrop = movie['backdrop_path'] as String?;
                                final poster = movie['poster_path'] as String?;
                                final item = MediaItem(
                                  id: movie['id'].toString(),
                                  title: movie['title'] ?? 'Untitled',
                                  rating: (movie['vote_average'] as num?)?.toDouble(),
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
                                  backdropUrl: backdrop != null && backdrop.isNotEmpty
                                      ? imageBaseUrl2 + backdrop
                                      : null,
                                );
                                return Padding(
                                  padding: const EdgeInsets.all(8),
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
                          },
                          error: (error, stackTrace) => Text("Error $error"),
                          loading: () => const CircularProgressIndicator(
                            color: ColorPalette.primaryGreen,
                          ),
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
                        topRatedMovies.when(
                          data: (data) {
                            return HorizontalMediaCarousel(
                              height: responsive.animePosterHeight,
                              itemCount: data.length,
                              itemBuilder: (context, index) {
                                final movie = data[index];
                                final backdrop = movie['backdrop_path'] as String?;
                                final poster = movie['poster_path'] as String?;
                                final item = MediaItem(
                                  id: movie['id'].toString(),
                                  title: movie['title'] ?? 'Untitled',
                                  rating: (movie['vote_average'] as num?)?.toDouble(),
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
                                  backdropUrl: backdrop != null && backdrop.isNotEmpty
                                      ? imageBaseUrl2 + backdrop
                                      : null,
                                );
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
                          },
                          error: (error, stackTrace) => Text("Error $error"),
                          loading: () => const CircularProgressIndicator(
                            color: ColorPalette.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 6. Genre-Based Movie Sections
                  ..._buildGenreSections(context, ref, responsive),
                ],
              ),
            ),

            // Pinned Frosted Sparrow Header at Top
            const Positioned(top: 0, left: 0, right: 0, child: SparrowHeader()),
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

    return genresAsync.when(
      data: (allGenres) {
        final genresToShow = allGenres
            .where((g) => selectedGenreIds.contains(g.id))
            .toList();

        return genresToShow.map((genre) {
          final moviesAsync = ref.watch(movieByGenreProvider(genre.id));
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
                    moviesAsync.when(
                      data: (items) {
                        if (items.isEmpty) return const SizedBox.shrink();
                        return HorizontalMediaCarousel(
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
                      },
                      loading: () => SizedBox(
                        height: responsive.animePosterHeight,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: ColorPalette.primaryGreen,
                          ),
                        ),
                      ),
                      error: (error, stack) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList();
      },
      loading: () => const [SizedBox.shrink()],
      error: (_, __) => const [SizedBox.shrink()],
    );
  }
}
