import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sparrow/features/anime%20hub/providers/anime_tv_providers.dart';
import 'package:sparrow/features/anime%20hub/widgets/anime_hero_section.dart';
import 'package:sparrow/features/continue_watching/data/continue_watching_item.dart';
import 'package:sparrow/features/continue_watching/providers/continue_watching_provider.dart';
import 'package:sparrow/features/home%20page/widgets/continue_watching_card.dart';
import 'package:sparrow/features/home%20page/widgets/horizontal_media_carousel.dart';
import 'package:sparrow/features/player/models/playback_context.dart';
import 'package:sparrow/features/home%20page/widgets/portrait_poster_card.dart';
import 'package:sparrow/features/home%20page/widgets/section_header.dart';
import 'package:sparrow/features/home%20page/widgets/sparrow_header.dart';
import 'package:sparrow/features/view_all/view_all_args.dart';
import 'package:sparrow/navigation/dpad_navigation.dart';
import 'package:sparrow/shared/genre_providers.dart';
import 'package:sparrow/shared/media_item.dart';
import 'package:sparrow/shared/navigation/tv_show_navigation.dart';
import 'package:sparrow/shared/navigation/view_all_navigation.dart';
import '../../../shared/scroll_aware_header.dart';
import '../../../shared/responsive_utils.dart';
import '../../../theme/color_palette.dart';

class AnimeHubPage extends ConsumerStatefulWidget {
  const AnimeHubPage({super.key});

  @override
  ConsumerState<AnimeHubPage> createState() => _AnimeHubPageState();
}

class _AnimeHubPageState extends ConsumerState<AnimeHubPage> {
  final _headerController = ScrollAwareHeaderController();

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final topPadding = responsive.padding.top;
    final headerHeight = responsive.headerHeight;

    final trendingTvAsync = ref.watch(trendingTvShowsProvider);
    final animeSeriesAsync = ref.watch(topAnimeSeriesProvider);
    final popularTvAsync = ref.watch(popularTvShowsProvider);
    final topRatedTvAsync = ref.watch(topRatedTvShowsProvider);
    final onTheAirTvAsync = ref.watch(onTheAirTvShowsProvider);

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
            // Scrollable Hub Content
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
                  // 1. Featured Anime & TV Hero Carousel
                  AnimeHeroSection(
                    onWatchNow: (item) => openTvShowDetails(context, item),
                  ),

                  // Continue Watching Section (Reactive local Hive storage, hidden if empty)
                  _buildTvContinueWatchingSection(context, responsive),

                  SizedBox(height: responsive.scale(16, min: 12, max: 22)),

                  // 2. Top Anime & Animation Series
                  DpadRegion(
                    memoryKey: 'tv/animeSeries',
                    leftEdge: DpadEdgeBehavior.leave,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(
                          leadingIcon: Icons.auto_awesome_rounded,
                          title: 'Top Anime & Animation',
                          actionText: 'View All',
                          onTrailingTap: () {
                            openViewAll(
                              context,
                              const ViewAllArgs(
                                mediaType: 'tv',
                                categoryType: 'genre',
                                genreId: 16,
                                title: 'Top Anime & Animation',
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        _buildPosterCarousel(
                          asyncValue: animeSeriesAsync,
                          height: responsive.animePosterHeight,
                          width: responsive.animePosterWidth,
                          responsive: responsive,
                          onRetry: () => ref.refresh(topAnimeSeriesProvider),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: responsive.scale(18, min: 12, max: 24)),

                  // 3. Trending TV Shows Today
                  DpadRegion(
                    memoryKey: 'tv/trendingTv',
                    leftEdge: DpadEdgeBehavior.leave,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(
                          overline: 'TOP PICKS TODAY',
                          title: 'Trending TV Shows',
                          actionText: 'View All',
                          onTrailingTap: () {
                            openViewAll(
                              context,
                              const ViewAllArgs(
                                mediaType: 'tv',
                                categoryType: 'trending',
                                title: 'Trending TV Shows',
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        _buildPosterCarousel(
                          asyncValue: trendingTvAsync,
                          height: responsive.trendingPosterHeight,
                          width: responsive.trendingPosterWidth,
                          responsive: responsive,
                          isTrending: true,
                          onRetry: () => ref.refresh(trendingTvShowsProvider),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: responsive.scale(18, min: 12, max: 24)),

                  // 4. Popular TV Series
                  DpadRegion(
                    memoryKey: 'tv/popularTv',
                    leftEdge: DpadEdgeBehavior.leave,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(
                          leadingIcon: Icons.local_fire_department_rounded,
                          title: 'Popular TV Shows',
                          tag: 'HOT',
                          actionText: 'View All',
                          onTrailingTap: () {
                            openViewAll(
                              context,
                              const ViewAllArgs(
                                mediaType: 'tv',
                                categoryType: 'popular',
                                title: 'Popular TV Shows',
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        _buildPosterCarousel(
                          asyncValue: popularTvAsync,
                          height: responsive.animePosterHeight,
                          width: responsive.animePosterWidth,
                          responsive: responsive,
                          onRetry: () => ref.refresh(popularTvShowsProvider),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: responsive.scale(18, min: 12, max: 24)),

                  // 5. On The Air / Airing Today
                  DpadRegion(
                    memoryKey: 'tv/onTheAirTv',
                    leftEdge: DpadEdgeBehavior.leave,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(
                          title: 'Currently Airing Series',
                          subtitle: 'Catch the latest weekly broadcast episodes',
                          actionText: 'View All',
                          onTrailingTap: () {
                            openViewAll(
                              context,
                              const ViewAllArgs(
                                mediaType: 'tv',
                                categoryType: 'on_the_air',
                                title: 'Currently Airing Series',
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        _buildPosterCarousel(
                          asyncValue: onTheAirTvAsync,
                          height: responsive.animePosterHeight,
                          width: responsive.animePosterWidth,
                          responsive: responsive,
                          onRetry: () => ref.refresh(onTheAirTvShowsProvider),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: responsive.scale(18, min: 12, max: 24)),

                  // 6. Critically Acclaimed TV Shows
                  DpadRegion(
                    memoryKey: 'tv/topRatedTv',
                    leftEdge: DpadEdgeBehavior.leave,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(
                          title: 'Critically Acclaimed Shows',
                          tag: 'TOP RATED',
                          actionText: 'View All',
                          onTrailingTap: () {
                            openViewAll(
                              context,
                              const ViewAllArgs(
                                mediaType: 'tv',
                                categoryType: 'top_rated',
                                title: 'Critically Acclaimed Shows',
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        _buildPosterCarousel(
                          asyncValue: topRatedTvAsync,
                          height: responsive.animePosterHeight,
                          width: responsive.animePosterWidth,
                          responsive: responsive,
                          onRetry: () => ref.refresh(topRatedTvShowsProvider),
                        ),
                      ],
                    ),
                  ),

                  // 7. Genre-Based TV Sections (Self-contained to prevent full-page rebuilds)
                  ..._buildTvGenreSections(context, ref, responsive),
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
              child: const SparrowHeader(subtitle: 'ANIME & TV'),
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildTvContinueWatchingSection(
    BuildContext context,
    SparrowResponsive responsive,
  ) {
    final tvItems = ref.watch(tvContinueWatchingProvider);
    if (tvItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: responsive.scale(16, min: 12, max: 22)),
        DpadRegion(
          memoryKey: 'tv/continueWatching',
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
                itemCount: tvItems.length,
                itemBuilder: (context, index) {
                  final entry = tvItems[index];
                  final item = entry.toMediaItem();
                  return ContinueWatchingCard(
                    item: item,
                    width: responsive.continueWatchingWidth,
                    onTap: () => _openTvContinueWatchingItem(context, entry),
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
      ],
    );
  }

  void _openTvContinueWatchingItem(
    BuildContext context,
    ContinueWatchingItem entry,
  ) {
    final playbackContext = PlaybackContext.tv(
      item: entry.toMediaItem(),
      season: entry.season,
      episode: entry.episode,
      episodeTitle: entry.episodeTitle,
    );
    context.push('/player', extra: playbackContext);
  }

  Widget _buildPosterCarousel({
    required AsyncValue<List<MediaItem>> asyncValue,
    required double height,
    required double width,
    required dynamic responsive,
    required VoidCallback onRetry,
    bool isTrending = false,
  }) {
    if (asyncValue.hasValue &&
        asyncValue.value != null &&
        asyncValue.value!.isNotEmpty) {
      final items = asyncValue.value!;
      return HorizontalMediaCarousel(
        height: height,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: FocusablePosterCard(
              onSelected: () => openTvShowDetails(context, item),
              child: PortraitPosterCard(
                item: item,
                width: width,
                trending: isTrending,
                index: index,
                onTap: () => openTvShowDetails(context, item),
              ),
            ),
          );
        },
      );
    }

    if (asyncValue.isLoading) {
      return SizedBox(
        height: height,
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: ColorPalette.primaryGreen,
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
              const Icon(Icons.wifi_off_rounded,
                  size: 18, color: ColorPalette.textMuted),
              Text(
                'Unable to load TV shows',
                style: TextStyle(
                  color: ColorPalette.textMuted,
                  fontSize: responsive.sp(12, min: 10, max: 14),
                ),
                textAlign: TextAlign.center,
              ),
              TextButton(
                onPressed: onRetry,
                child: const Text('Retry',
                    style: TextStyle(color: ColorPalette.primaryGreen)),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  List<Widget> _buildTvGenreSections(
    BuildContext context,
    WidgetRef ref,
    SparrowResponsive responsive,
  ) {
    final genresAsync = ref.watch(tvGenresProvider);
    const selectedGenreIds = [10759, 18, 35, 80, 9648, 10765];

    final allGenres = genresAsync.value ?? fallbackTvGenres;
    final genresToShow =
        allGenres.where((g) => selectedGenreIds.contains(g.id)).toList();

    return genresToShow
        .map((genre) => _TvGenreSection(genre: genre, responsive: responsive))
        .toList();
  }
}

/// Independent consumer section for TV genres to avoid rebuilding the entire page.
class _TvGenreSection extends ConsumerWidget {
  final TmdbGenre genre;
  final SparrowResponsive responsive;

  const _TvGenreSection({
    required this.genre,
    required this.responsive,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tvAsync = ref.watch(tvByGenreProvider(genre.id));

    Widget content;
    if (tvAsync.hasValue && tvAsync.value != null && tvAsync.value!.isNotEmpty) {
      final items = tvAsync.value!;
      content = HorizontalMediaCarousel(
        height: responsive.animePosterHeight,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: FocusablePosterCard(
              onSelected: () => openTvShowDetails(context, item),
              child: PortraitPosterCard(
                item: item,
                width: responsive.animePosterWidth,
                onTap: () => openTvShowDetails(context, item),
              ),
            ),
          );
        },
      );
    } else if (tvAsync.isLoading) {
      content = SizedBox(
        height: responsive.animePosterHeight,
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: ColorPalette.primaryGreen,
          ),
        ),
      );
    } else if (tvAsync.hasError) {
      content = SizedBox(
        height: 60,
        child: Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                'Could not load ${genre.name}',
                style: const TextStyle(color: ColorPalette.textMuted, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              TextButton(
                onPressed: () => ref.refresh(tvByGenreProvider(genre.id)),
                child: const Text('Retry',
                    style: TextStyle(color: ColorPalette.primaryGreen)),
              ),
            ],
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
          memoryKey: 'tv/genre_${genre.id}',
          leftEdge: DpadEdgeBehavior.leave,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: genre.name,
                actionText: 'View All',
                onTrailingTap: () {
                  openViewAll(
                    context,
                    ViewAllArgs(
                      mediaType: 'tv',
                      categoryType: 'genre',
                      genreId: genre.id,
                      title: '${genre.name} Shows',
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
