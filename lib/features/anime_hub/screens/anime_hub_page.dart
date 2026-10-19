import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparrow/features/anime_hub/providers/anime_tv_providers.dart';
import 'package:sparrow/features/anime_hub/widgets/anime_hero_section.dart';
import 'package:sparrow/features/home%20page/widgets/horizontal_media_carousel.dart';
import 'package:sparrow/features/home%20page/widgets/landscape_media_card.dart';
import 'package:sparrow/features/home%20page/widgets/portrait_poster_card.dart';
import 'package:sparrow/features/home%20page/widgets/section_header.dart';
import 'package:sparrow/features/home%20page/widgets/sparrow_header.dart';
import 'package:sparrow/features/view_all/view_all_args.dart';
import 'package:sparrow/shared/genre_providers.dart';
import 'package:sparrow/shared/media_item.dart';
import 'package:sparrow/shared/navigation/tv_show_navigation.dart';
import 'package:sparrow/shared/navigation/view_all_navigation.dart';
import 'package:sparrow/shared/responsive_utils.dart';
import 'package:sparrow/theme/color_palette.dart';

class AnimeHubPage extends ConsumerStatefulWidget {
  const AnimeHubPage({super.key});

  @override
  ConsumerState<AnimeHubPage> createState() => _AnimeHubPageState();
}

class _AnimeHubPageState extends ConsumerState<AnimeHubPage> {
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
            SingleChildScrollView(
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

                  SizedBox(height: responsive.scale(16, min: 12, max: 22)),

                  // 2. Top Anime & Animation Series
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
                  ),

                  SizedBox(height: responsive.scale(18, min: 12, max: 24)),

                  // 3. Trending TV Shows Today
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
                  ),

                  SizedBox(height: responsive.scale(18, min: 12, max: 24)),

                  // 4. Popular TV Series
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
                  ),

                  SizedBox(height: responsive.scale(18, min: 12, max: 24)),

                  // 5. On The Air / Airing Today (Landscape Cards)
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
                  ),

                  SizedBox(height: responsive.scale(18, min: 12, max: 24)),

                  // 6. Critically Acclaimed TV Shows
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
                  ),

                  // 7. Genre-Based TV Sections
                  ..._buildTvGenreSections(context, ref, responsive),
                ],
              ),
            ),

            // Pinned Frosted Sparrow Header at Top
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SparrowHeader(subtitle: 'ANIME & TV'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPosterCarousel({
    required AsyncValue<List<MediaItem>> asyncValue,
    required double height,
    required double width,
    required dynamic responsive,
    bool isTrending = false,
  }) {
    return asyncValue.when(
      data: (items) {
        if (items.isEmpty) {
          return const SizedBox.shrink();
        }

        return HorizontalMediaCarousel(
          height: height,
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return PortraitPosterCard(
              item: item,
              width: width,
              trending: isTrending,
              index: index,
              onTap: () => openTvShowDetails(context, item),
            );
          },
        );
      },
      loading: () => SizedBox(
        height: height,
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: ColorPalette.primaryGreen,
          ),
        ),
      ),
      error: (error, stack) => SizedBox(
        height: 80,
        child: Center(
          child: Text(
            'Unable to load TV shows',
            style: TextStyle(
              color: ColorPalette.textMuted,
              fontSize: responsive.sp(12, min: 10, max: 14),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLandscapeCarousel({
    required AsyncValue<List<MediaItem>> asyncValue,
    required double height,
    required double width,
    required dynamic responsive,
  }) {
    return asyncValue.when(
      data: (items) {
        if (items.isEmpty) {
          return const SizedBox.shrink();
        }

        return HorizontalMediaCarousel(
          height: height,
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return LandscapeMediaCard(
              item: item,
              width: width,
              onTap: () => openTvShowDetails(context, item),
            );
          },
        );
      },
      loading: () => SizedBox(
        height: height,
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: ColorPalette.primaryGreen,
          ),
        ),
      ),
      error: (error, stack) => SizedBox(
        height: 80,
        child: Center(
          child: Text(
            'Unable to load on-air shows',
            style: TextStyle(
              color: ColorPalette.textMuted,
              fontSize: responsive.sp(12, min: 10, max: 14),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTvGenreSections(
    BuildContext context,
    WidgetRef ref,
    SparrowResponsive responsive,
  ) {
    final genresAsync = ref.watch(tvGenresProvider);
    const selectedGenreIds = [10759, 18, 35, 80, 9648, 10765];

    return genresAsync.when(
      data: (allGenres) {
        final genresToShow = allGenres
            .where((g) => selectedGenreIds.contains(g.id))
            .toList();

        return genresToShow.map((genre) {
          final tvAsync = ref.watch(tvByGenreProvider(genre.id));
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: responsive.scale(18, min: 12, max: 24)),
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
              _buildPosterCarousel(
                asyncValue: tvAsync,
                height: responsive.animePosterHeight,
                width: responsive.animePosterWidth,
                responsive: responsive,
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
