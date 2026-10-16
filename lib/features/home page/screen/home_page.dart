import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparrow/features/home%20page/data/media_item.dart';
import 'package:sparrow/features/home%20page/providers/movieProvider.dart';
import 'package:sparrow/shared/tmdb_base_url.dart';
import '../../../shared/responsive_utils.dart';
import '../../../theme/color_palette.dart';
import '../data/mock_home_data.dart';
import '../widgets/continue_watching_card.dart';
import '../widgets/featured_hero_card.dart';
import '../widgets/floating_bottom_nav.dart';
import '../widgets/horizontal_media_carousel.dart';
import '../widgets/landscape_media_card.dart';
import '../widgets/portrait_poster_card.dart';
import '../widgets/section_header.dart';
import '../widgets/sparrow_header.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final topPadding = responsive.padding.top;
    final headerHeight = responsive.headerHeight;
    final movieProvider = ref.watch(movieProviderNotifier);
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
            // tileMode: TileMode.repeated,
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
                  FeaturedHeroSection(onWatchNow: (item) {}),

                  SizedBox(height: responsive.scale(14, min: 10, max: 20)),

                  // 2. Continue Watching Section
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
                          final item = MediaItem(
                            id: movie['id'].toString(),
                            title: movie['title'] ?? 'Untitled',
                            rating: (movie['vote_average'] as num?)?.toDouble(),
                            ratingCount: movie['vote_count']?.toString(),
                            imageUrl: imageBaseUrl + movie['backdrop_path'],
                            genres: movie['genre'],
                          );
                          return ContinueWatchingCard(
                            item: item,
                            width: responsive.continueWatchingWidth,
                            onTap: () {},
                          );
                        },
                      );
                    },
                    error: (error, stackTrace) => Text("erroe: $error"),
                    loading: () => CircularProgressIndicator(
                      color: ColorPalette.primaryGreen,
                    ),
                  ),

                  SizedBox(height: responsive.scale(18, min: 12, max: 24)),

                  // 3. Trending Now Section
                  SectionHeader(
                    overline: 'TOP PICKS TODAY',
                    title: 'Trending Now',
                    trailing: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: ColorPalette.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  trendingNowMovies.when(
                    data: (data) {
                      return HorizontalMediaCarousel(
                        height: responsive.trendingPosterHeight,
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          final movie = data[index];
                          final item = MediaItem(
                            id: movie['id'].toString(),
                            title: movie['title'] ?? 'Untitled',
                            rating: (movie['vote_average'] as num?)?.toDouble(),
                            ratingCount: movie['vote_count']?.toString(),
                            imageUrl: imageBaseUrl + movie['poster_path'],
                            genres: movie['genre'],
                          );
                          return PortraitPosterCard(
                            item: item,
                            width: responsive.trendingPosterWidth,
                            trending: true,
                            index: index,
                            onTap: () {},
                          );
                        },
                      );
                    },
                    error: (error, stackTrace) => Text("Error $error"),
                    loading: () => CircularProgressIndicator(
                      color: ColorPalette.primaryGreen,
                    ),
                  ),

                  SizedBox(height: responsive.scale(18, min: 12, max: 24)),

                  // 5. Popular Movie Section
                  SectionHeader(
                    leadingIcon: Icons.auto_awesome_rounded,
                    title: 'Popular Movies',
                    actionText: 'Anime Hub',
                    onTrailingTap: () {},
                  ),
                  const SizedBox(height: 8),
                  popularMovies.when(
                    data: (data) {
                      return HorizontalMediaCarousel(
                        height: responsive.animePosterHeight,
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          final movie = data[index];
                          final item = MediaItem(
                            id: movie['id'].toString(),
                            title: movie['title'] ?? 'Untitled',
                            rating: (movie['vote_average'] as num?)?.toDouble(),
                            ratingCount: movie['vote_count']?.toString(),
                            imageUrl: imageBaseUrl + movie['poster_path'],
                            genres: movie['genre'],
                          );
                          return PortraitPosterCard(
                            item: item,
                            width: responsive.animePosterWidth,
                            onTap: () {},
                          );
                        },
                      );
                    },
                    error: (error, stackTrace) {
                      return Text("Error $error");
                    },
                    loading: () {
                      return CircularProgressIndicator(
                        color: ColorPalette.primaryGreen,
                      );
                    },
                  ),

                  SizedBox(height: responsive.scale(18, min: 12, max: 24)),

                  // 6. Blockbusters & Classics Section
                  SectionHeader(
                    title: 'Blockbusters & Classics',
                    trailing: Text(
                      'Worldwide Hits',
                      style: TextStyle(
                        color: ColorPalette.textMuted,
                        fontSize: responsive.sp(11, min: 9.5, max: 12),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  topRatedMovies.when(
                    data: (data) {
                      return HorizontalMediaCarousel(
                        height: responsive.blockbusterHeight,
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          final movie = data[index];
                          final item = MediaItem(
                            id: movie['id'].toString(),
                            title: movie['title'] ?? 'Untitled',
                            rating: (movie['vote_average'] as num?)?.toDouble(),
                            ratingCount: movie['vote_count']?.toString(),
                            imageUrl: imageBaseUrl + movie['poster_path'],
                            genres: movie['genre'],
                          );
                          return LandscapeMediaCard(
                            item: item,
                            width: responsive.blockbusterWidth,
                            onTap: () {},
                          );
                        },
                      );
                    },
                    error: (error, stackTrace) {
                      return Text("Error $error");
                    },
                    loading: () {
                      return CircularProgressIndicator(
                        color: ColorPalette.primaryGreen,
                      );
                    },
                  ),
                ],
              ),
            ),

            // Pinned Frosted Sparrow Header at Top
            const Positioned(top: 0, left: 0, right: 0, child: SparrowHeader()),

            // Floating Frosted Bottom Navigation Bar
            FloatingBottomNav(
              currentIndex: _currentNavIndex,
              onTabSelected: (index) {
                setState(() {
                  _currentNavIndex = index;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
