import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparrow/features/anime%20hub/providers/anime_tv_providers.dart';
import 'package:sparrow/navigation/main_shell_scaffold.dart';
import 'package:sparrow/shared/error_image_placeholder.dart';
import 'package:sparrow/shared/media_item.dart';
import 'package:sparrow/shared/responsive_utils.dart';
import 'package:sparrow/theme/color_palette.dart';

class AnimeHeroSection extends ConsumerStatefulWidget {
  final ValueChanged<MediaItem>? onWatchNow;

  const AnimeHeroSection({super.key, this.onWatchNow});

  @override
  ConsumerState<AnimeHeroSection> createState() => _AnimeHeroSectionState();
}

class _AnimeHeroSectionState extends ConsumerState<AnimeHeroSection> {
  late final CarouselSliderController _carouselController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _carouselController = CarouselSliderController();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final animeListAsync = ref.watch(topAnimeSeriesProvider);

    final carouselHeight = responsive.layeredCarouselHeight;
    final cardHeight = responsive.heroCardHeight;
    final posterHeight = responsive.heroPosterHeight;

    final viewportFraction = responsive.isTvOrDesktop
        ? 0.25
        : (responsive.isTablet ? 0.40 : 0.66);

    // 1. Render existing data whenever available (even during background refresh)
    if (animeListAsync.hasValue &&
        animeListAsync.value != null &&
        animeListAsync.value!.isNotEmpty) {
      final items = animeListAsync.value!;
      final displayItems = items.take(8).toList();
      final selectedIndex = _selectedIndex.clamp(0, displayItems.length - 1);

      return SizedBox(
        height: carouselHeight,
        child: DpadRegion(
          memoryKey: 'tv/animeHeroCarousel',
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
            itemCount: displayItems.length,
            options: CarouselOptions(
              height: carouselHeight,
              viewportFraction: viewportFraction,
              initialPage: selectedIndex,
              enableInfiniteScroll:
                  !responsive.isTvOrDesktop && (displayItems.length > 1),
              enlargeCenterPage: false,
              padEnds: true,
              scrollPhysics: const BouncingScrollPhysics(),
              onPageChanged: (index, reason) {
                if (mounted) {
                  setState(() {
                    _selectedIndex = index;
                  });
                }
              },
            ),
            itemBuilder: (context, index, realIndex) {
              final isCurrent = index == selectedIndex;
              final item = displayItems[index];

              return _LayeredTvCard(
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
    }

    // 2. Initial loading state
    if (animeListAsync.isLoading) {
      return SizedBox(
        height: carouselHeight,
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: ColorPalette.primaryGreen,
          ),
        ),
      );
    }

    // 3. Error state with retry
    if (animeListAsync.hasError) {
      return SizedBox(
        height: 100,
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
                'Unable to load featured shows',
                style: TextStyle(color: ColorPalette.textMuted),
                textAlign: TextAlign.center,
              ),
              TextButton(
                onPressed: () => ref.refresh(topAnimeSeriesProvider),
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

class _LayeredTvCard extends StatelessWidget {
  final MediaItem item;
  final bool isCurrent;
  final double cardHeight;
  final double posterHeight;
  final VoidCallback onTap;
  final VoidCallback onWatchNow;

  const _LayeredTvCard({
    required this.item,
    required this.isCurrent,
    required this.cardHeight,
    required this.posterHeight,
    required this.onTap,
    required this.onWatchNow,
  });

  @override
  Widget build(BuildContext context) {
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

    final cardWidget = GestureDetector(
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
                      // 17:16 aspect ratio poster
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
                                        placeholder: (context, url) =>
                                            Container(
                                              color: ColorPalette
                                                  .surfaceContainerLow,
                                              child: const Center(
                                                child: SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: ColorPalette
                                                            .primaryGreen,
                                                      ),
                                                ),
                                              ),
                                            ),
                                      )
                                    : const ErrorImagePlaceholder(),
                                // Series Badge
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
                                      'TV SERIES',
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

                      // "Watch Series" button
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
                            'Watch Series',
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
        child: cardWidget,
      );
    }

    return cardWidget;
  }
}
