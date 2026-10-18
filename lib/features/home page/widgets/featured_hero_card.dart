import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparrow/features/home%20page/providers/movieProvider.dart';
import 'package:sparrow/shared/error_image_placeholder.dart';
import 'package:sparrow/shared/tmdb_base_url.dart';
import '../../../shared/responsive_utils.dart';
import '../../../theme/color_palette.dart';
import '../../../shared/media_item.dart';
import '../providers/featured_providers.dart';
import 'network_media_image.dart';

/// Complete Layered Featured Hero Section.
///
/// Design Specifications:
/// - No external container wrapping the entire carousel widget.
/// - EACH movie card is its own rounded brown container (#281913) containing:
///   1. 17:16 exact aspect ratio poster artwork (clean, zero overlays).
///   2. Movie title.
///   3. Genre chips.
///   4. Star rating and review count.
///   5. "Watch Now" green action button.
/// - Layered overlapping presentation:
///   - The active movie card is centered, largest (scale 1.0), and dominant.
///   - Previous and next cards peek from behind on left and right, smaller (scale 0.86),
///     dropped vertically, with atmospheric depth dimming.
/// - Swiping horizontally smoothly changes the selected movie.
/// - Riverpod-driven state synchronization.
/// - Zero pagination dots.
/// - Fully responsive across mobile, tablet, and TV viewports without overflow.
class FeaturedHeroSection extends ConsumerStatefulWidget {
  final ValueChanged<MediaItem>? onWatchNow;
  const FeaturedHeroSection({super.key, this.onWatchNow});

  @override
  ConsumerState<FeaturedHeroSection> createState() =>
      _FeaturedHeroSectionState();
}

class _FeaturedHeroSectionState extends ConsumerState<FeaturedHeroSection> {
  late final CarouselSliderController _carouselController;

  @override
  void initState() {
    super.initState();
    _carouselController = CarouselSliderController();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final featuredmovies = ref.watch(movieProviderNotifier);
    // final featuredItems = ref.watch(featuredListProvider);
    final selectedIndex = ref.watch(selectedFeaturedIndexProvider);

    if (featuredmovies.isLoading) {
      return const CircularProgressIndicator();
    }

    final carouselHeight = responsive.layeredCarouselHeight;
    final cardHeight = responsive.heroCardHeight;
    final posterHeight = responsive.heroPosterHeight;

    // Viewport fraction: on mobile ~0.76 centers active card while
    // previous and next cards peek symmetrically from behind on left and right
    final viewportFraction = responsive.isTvOrDesktop
        ? 0.25
        : (responsive.isTablet ? 0.40 : 0.66);
    return featuredmovies.when(
      data: (data) {
        //debugPrintt("data is $data");
        return LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              height: carouselHeight,
              child: CarouselSlider.builder(
                carouselController: _carouselController,
                itemCount: data.length,
                options: CarouselOptions(
                  height: carouselHeight,
                  viewportFraction: viewportFraction,
                  initialPage: selectedIndex,
                  enableInfiniteScroll: true,
                  enlargeCenterPage:
                      false, // Custom 3D layered transform inside _LayeredMovieCard
                  padEnds: true,
                  scrollPhysics: const BouncingScrollPhysics(),
                  onPageChanged: (index, reason) {
                    // Update Riverpod selection state cleanly on settle
                    ref.read(selectedFeaturedIndexProvider.notifier).state =
                        index;
                  },
                ),
                itemBuilder: (context, index, realIndex) {
                  final isCurrent = index == selectedIndex;
                  final movieInfo = data[index];

                  final backdrop = movieInfo['backdrop_path'] as String?;
                  final poster = movieInfo['poster_path'] as String?;
                  final item = MediaItem(
                    id: movieInfo['id'].toString(),
                    title: movieInfo['title'] ?? 'Untitled',
                    rating: (movieInfo['vote_average'] as num?)?.toDouble(),
                    ratingCount: movieInfo['vote_count']?.toString(),
                    imageUrl: poster != null && poster.isNotEmpty
                        ? imageBaseUrl + poster
                        : (backdrop != null && backdrop.isNotEmpty
                              ? imageBaseUrl + backdrop
                              : ''),
                    genres: movieInfo['genre'] ?? [],
                    isAdult: movieInfo['adult'] as bool? ?? false,
                    overview: movieInfo['overview'] as String?,
                    releaseDate: movieInfo['release_date'] as String?,
                    backdropUrl: backdrop != null && backdrop.isNotEmpty
                        ? imageBaseUrl2 + backdrop
                        : null,
                  );
                  return _LayeredMovieCard(
                    item: item,
                    isCurrent: isCurrent,
                    cardHeight: cardHeight,
                    posterHeight: posterHeight,
                    // movieInfo: data[index],
                    onTap: () {
                      if (!isCurrent) {
                        _carouselController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                        );
                      } else {
                        widget.onWatchNow?.call(item);
                      }
                    },
                    onWatchNow: () => widget.onWatchNow?.call(item),
                  );
                },
              ),
            );
          },
        );
      },
      error: (error, stack) => Text("error : $error"),
      loading: () {
        return CircularProgressIndicator(color: ColorPalette.primaryGreen);
      },
    );
  }
}

/// Individual movie card in the layered carousel.
///
/// Serves as the self-contained rounded brown container (#281913) enclosing:
/// - 17:16 exact aspect ratio poster (with BoxFit.cover and zero overlays).
/// - Title, genre chips, star rating, and "Watch Now" action button.
class _LayeredMovieCard extends StatelessWidget {
  final MediaItem item;
  final bool isCurrent;
  final double cardHeight;
  final double posterHeight;
  final VoidCallback onTap;
  final VoidCallback onWatchNow;
  // final Map? movieInfo;

  const _LayeredMovieCard({
    required this.item,
    required this.isCurrent,
    required this.cardHeight,
    required this.posterHeight,
    required this.onTap,
    required this.onWatchNow,
    // this.movieInfo,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    // Active card: scale 1.0, translateY 0.
    // Background card: scale ~0.86, dropped vertically ~16dp, atmospheric dimming.
    final scale = isCurrent ? 1.0 : 0.86;
    final translateY = isCurrent
        ? 0.0
        : responsive.scale(16.0, min: 12.0, max: 20.0);
    final cardRadius = responsive.heroContainerRadius;
    final posterRadius = responsive.radius(16.0);

    final paddingH = responsive.scale(10.0, min: 8.0, max: 14.0);
    final paddingTop = responsive.scale(10.0, min: 8.0, max: 14.0);
    final paddingBottom = responsive.scale(12.0, min: 10.0, max: 16.0);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, translateY, 0),
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          child: Center(
            child: Container(
              key: isCurrent
                  ? const Key('featured_brown_container')
                  : ValueKey('featured_card_${item.id}'),
              margin: EdgeInsets.symmetric(
                horizontal: responsive.scale(6.0, min: 4.0, max: 10.0),
              ),
              decoration: BoxDecoration(
                color: ColorPalette
                    .heroContainer, // Dark muted brown surface (#281913)
                borderRadius: BorderRadius.circular(cardRadius),
                border: Border.all(
                  color: isCurrent
                      ? ColorPalette.primaryGreen.withValues(alpha: 0.65)
                      : ColorPalette.heroBorder.withValues(alpha: 0.60),
                  width: isCurrent ? 1.5 : 1.0,
                ),
                // boxShadow: [
                //   BoxShadow(
                //     color: isCurrent
                //         ? ColorPalette.primaryGreen.withValues(alpha: 0.20)
                //         : Colors.black.withValues(alpha: 0.70),
                //     blurRadius: isCurrent ? 20 : 10,
                //     offset: Offset(0, isCurrent ? 8 : 4),
                //   ),
                // ],
              ),
              clipBehavior: Clip.antiAlias,
              padding: EdgeInsets.fromLTRB(
                paddingH,
                paddingTop,
                paddingH,
                paddingBottom,
              ),
              child: Stack(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 1. Movie Poster (Exact 17:16 aspect ratio, ZERO overlays)
                      SizedBox(
                        height: posterHeight,
                        child: AspectRatio(
                          aspectRatio: 16.0 / 17.0,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(posterRadius),
                            child: CachedNetworkImage(
                              imageUrl: item.imageUrl,
                              placeholder: (context, url) => Center(
                                child: SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: ColorPalette.primaryGreen,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) =>
                                  ErrorImagePlaceholder(),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: responsive.scale(7, min: 4, max: 9)),

                      // 2. Movie Title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          item.title,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ColorPalette.fontWhite,
                            fontSize: responsive.sp(17, min: 14.5, max: 20),
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),

                      SizedBox(height: responsive.scale(5, min: 3, max: 7)),

                      // 3. Genre Chips
                      Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        alignment: WrapAlignment.center,
                        children: item.genres.map<Widget>((genre) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: responsive.scale(7, min: 5, max: 9),
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: ColorPalette.heroChipBackground.withValues(
                                alpha: 0.90,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: ColorPalette.ghostBorder.withValues(
                                  alpha: 0.08,
                                ),
                                width: 0.6,
                              ),
                            ),
                            child: Text(
                              genre,
                              style: TextStyle(
                                color: ColorPalette.textSecondary,
                                fontSize: responsive.sp(9, min: 7.5, max: 10.5),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      SizedBox(height: responsive.scale(5, min: 3, max: 7)),

                      // 4. Star Rating & Review Count
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (int i = 0; i < 4; i++)
                            Icon(
                              Icons.star_rounded,
                              size: responsive.iconSize(13, min: 11, max: 15),
                              color: ColorPalette.primaryGreen,
                            ),
                          Icon(
                            Icons.star_half_rounded,
                            size: responsive.iconSize(13, min: 11, max: 15),
                            color: ColorPalette.primaryGreen,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${item.rating ?? 8.8}',
                            style: TextStyle(
                              color: ColorPalette.fontWhite,
                              fontSize: responsive.sp(10.5, min: 8.5, max: 12),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '(${item.ratingCount ?? "142k"})',
                            style: TextStyle(
                              color: ColorPalette.textMuted,
                              fontSize: responsive.sp(9.5, min: 8, max: 11),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: responsive.scale(7, min: 5, max: 10)),

                      // 5. Watch Now Action Button (Inside this movie's brown container)
                      ElevatedButton.icon(
                        onPressed: onWatchNow,

                        icon: Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.black,
                          size: responsive.iconSize(18, min: 15, max: 21),
                        ),
                        label: Text(
                          'Watch Now',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: responsive.sp(13, min: 11, max: 15),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorPalette.primaryGreen,
                          elevation: 2,
                          shadowColor: ColorPalette.primaryGreen.withValues(
                            alpha: 0.35,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: EdgeInsets.all(10),
                        ),
                      ),
                    ],
                  ),

                  // Atmospheric depth tint for background side cards
                  if (!isCurrent)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(cardRadius - 1),
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.42),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Backwards compatibility alias for FeaturedHeroSection.
typedef FeaturedHeroCarousel = FeaturedHeroSection;

/// Backwards compatibility single card widget.
class FeaturedHeroCard extends ConsumerWidget {
  final MediaItem item;
  final double? cardHeight;
  final VoidCallback? onWatchNow;

  const FeaturedHeroCard({
    super.key,
    required this.item,
    this.cardHeight,
    this.onWatchNow,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _LayeredMovieCard(
      item: item,
      isCurrent: true,
      cardHeight: cardHeight ?? 440.0,
      posterHeight: (cardHeight ?? 440.0) - 150.0,
      onTap: onWatchNow ?? () {},
      onWatchNow: onWatchNow ?? () {},
    );
  }
}
