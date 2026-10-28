import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparrow/features/continue_watching/providers/continue_watching_provider.dart';
import 'package:sparrow/features/home%20page/providers/movieProvider.dart';
import 'package:sparrow/navigation/main_shell_scaffold.dart';
import 'package:sparrow/shared/error_image_placeholder.dart';
import 'package:sparrow/shared/tmdb_base_url.dart';
import '../../../shared/responsive_utils.dart';
import '../../../theme/color_palette.dart';
import '../../../shared/media_item.dart';
import '../providers/featured_providers.dart';

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
    final fallbackItems = ref.watch(featuredListProvider);
    final selectedIndex = ref.watch(selectedFeaturedIndexProvider);

    final carouselHeight = responsive.layeredCarouselHeight;
    final cardHeight = responsive.heroCardHeight;
    final posterHeight = responsive.heroPosterHeight;

    final viewportFraction = responsive.isTvOrDesktop
        ? 0.25
        : (responsive.isTablet ? 0.40 : 0.66);

    // 1. Resolve items: live TMDB movies when available; otherwise fallback to curated mock heroes
    final List<MediaItem> items;
    if (featuredmovies.hasValue &&
        featuredmovies.value != null &&
        featuredmovies.value!.isNotEmpty) {
      items = featuredmovies.value!.map((movieInfo) {
        final backdrop = movieInfo['backdrop_path'] as String?;
        final poster = movieInfo['poster_path'] as String?;
        return MediaItem(
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
      }).toList();
    } else if (fallbackItems.isNotEmpty) {
      items = fallbackItems;
    } else {
      items = const [];
    }

    if (items.isNotEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            height: carouselHeight,
            child: DpadRegion(
              memoryKey: 'home/featuredCarousel',
              horizontalEdge: responsive.isTvOrDesktop
                  ? DpadEdgeBehavior.leave
                  : DpadEdgeBehavior.wrap,
              leftEdge: responsive.isTvOrDesktop ? DpadEdgeBehavior.stop : null,
              verticalEdge: DpadEdgeBehavior.leave,
              onEdge: (direction) {
                if (direction == TraversalDirection.left) {
                  TvDrawerScope.openOf(context);
                }
              },
              child: CarouselSlider.builder(
                carouselController: _carouselController,
                itemCount: items.length,
                options: CarouselOptions(
                  height: carouselHeight,
                  viewportFraction: viewportFraction,
                  initialPage: selectedIndex,
                  enableInfiniteScroll: !responsive.isTvOrDesktop,
                  enlargeCenterPage: false,
                  padEnds: true,
                  scrollPhysics: const BouncingScrollPhysics(),
                  onPageChanged: (index, reason) {
                    ref.read(selectedFeaturedIndexProvider.notifier).state =
                        index;
                  },
                ),
                itemBuilder: (context, index, realIndex) {
                  final isCurrent = index == selectedIndex;
                  final item = items[index];
                  return _LayeredMovieCard(
                    item: item,
                    isCurrent: isCurrent,
                    cardHeight: cardHeight,
                    posterHeight: posterHeight,
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
            ),
          );
        },
      );
    }

    // 2. Initial loading state (no cached or fallback data available)
    if (featuredmovies.isLoading) {
      return SizedBox(
        height: carouselHeight,
        child: const Center(
          child: CircularProgressIndicator(
            color: ColorPalette.primaryGreen,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    // 3. Error state with retry
    if (featuredmovies.hasError) {
      return SizedBox(
        height: carouselHeight,
        child: Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 20, color: ColorPalette.textMuted),
              const Text(
                'Unable to load featured movies',
                style: TextStyle(color: ColorPalette.textMuted),
                textAlign: TextAlign.center,
              ),
              TextButton(
                onPressed: () => ref.refresh(movieProviderNotifier),
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
}

/// Individual movie card in the layered carousel.
///
/// Serves as the self-contained rounded brown container (#281913) enclosing:
/// - 17:16 exact aspect ratio poster (with BoxFit.cover and zero overlays).
/// - Title, genre chips, star rating, and "Watch Now" action button.
class _LayeredMovieCard extends ConsumerWidget {
  final MediaItem item;
  final bool isCurrent;
  final double cardHeight;
  final double posterHeight;
  final VoidCallback onTap;
  final VoidCallback onWatchNow;

  const _LayeredMovieCard({
    required this.item,
    required this.isCurrent,
    required this.cardHeight,
    required this.posterHeight,
    required this.onTap,
    required this.onWatchNow,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsive = context.responsive;

    final scale = isCurrent ? 1.0 : 0.86;
    final translateY = isCurrent
        ? 0.0
        : responsive.scale(16.0, min: 12.0, max: 20.0);
    final cardRadius = responsive.heroContainerRadius;
    final posterRadius = responsive.radius(16.0);

    final paddingH = responsive.scale(10.0, min: 8.0, max: 14.0);
    final paddingTop = responsive.scale(10.0, min: 8.0, max: 14.0);
    final paddingBottom = responsive.scale(12.0, min: 10.0, max: 16.0);

    final cardContent = GestureDetector(
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
                color: ColorPalette.heroContainer,
                borderRadius: BorderRadius.circular(cardRadius),
                border: Border.all(
                  color: isCurrent
                      ? ColorPalette.primaryGreen.withValues(alpha: 0.65)
                      : ColorPalette.heroBorder.withValues(alpha: 0.60),
                  width: isCurrent ? 1.5 : 1.0,
                ),
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: ColorPalette.primaryGreen.withValues(
                            alpha: 0.25,
                          ),
                          blurRadius: 24,
                          spreadRadius: 2,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.70),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(cardRadius),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    paddingH,
                    paddingTop,
                    paddingH,
                    paddingBottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 16:17 aspect ratio poster
                      SizedBox(
                        height: posterHeight,
                        child: AspectRatio(
                          aspectRatio: 16 / 17,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(posterRadius),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                item.imageUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: item.imageUrl,
                                        fit: BoxFit.cover,
                                        memCacheWidth: 600,
                                        errorWidget: (context, url, error) =>
                                            const ErrorImagePlaceholder(),
                                        placeholder: (context, url) => Container(
                                          color: ColorPalette.surfaceContainerLow,
                                        ),
                                      )
                                    : const ErrorImagePlaceholder(),
                                // Movie Badge
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.75,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: ColorPalette.primaryGreen
                                            .withValues(alpha: 0.5),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      'MOVIE',
                                      style: TextStyle(
                                        color: ColorPalette.primaryGreen,
                                        fontSize: responsive.sp(
                                          8.5,
                                          min: 7.5,
                                          max: 9.5,
                                        ),
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: responsive.scale(8, min: 6, max: 10)),

                      // Title
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: ColorPalette.fontWhite,
                          fontSize: responsive.sp(14, min: 12, max: 16),
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Rating & Year
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (item.rating != null && item.rating! > 0) ...[
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Color(0xFF84FFA8),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              item.rating!.toStringAsFixed(1),
                              style: TextStyle(
                                color: ColorPalette.fontWhite,
                                fontSize: responsive.sp(
                                  11,
                                  min: 9.5,
                                  max: 12.5,
                                ),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (item.releaseDate != null &&
                              item.releaseDate!.length >= 4)
                            Text(
                              item.releaseDate!.substring(0, 4),
                              style: TextStyle(
                                color: ColorPalette.textMuted,
                                fontSize: responsive.sp(11, min: 9.5, max: 12),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: responsive.scale(8, min: 6, max: 10)),

                      // "Watch Now" action button
                      SizedBox(
                        height: responsive.scale(32, min: 28, max: 36),
                        child: ElevatedButton.icon(
                          onPressed: onWatchNow,
                          icon: const Icon(
                            Icons.play_arrow_rounded,
                            size: 16,
                            color: Colors.black,
                          ),
                          label: Text(
                            ref.watch(hasPlaybackProgressProvider(
                              item.isTvShow ? 'tv_${item.id}_s1_e1' : 'movie_${item.id}',
                            ))
                                ? 'Resume'
                                : 'Watch Now',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: responsive.sp(11.5, min: 10, max: 13),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorPalette.primaryGreen,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (responsive.isTvOrDesktop) {
      return DpadFocusable(
        onSelect: onWatchNow,
        onFocusChange: (focused) {
          if (focused && !isCurrent) {
            onTap();
          }
        },
        autoScroll: true,
        effects: const [],
        child: cardContent,
      );
    }

    return cardContent;
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
