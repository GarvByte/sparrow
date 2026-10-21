import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparrow/features/home%20page/widgets/portrait_poster_card.dart';
import 'package:sparrow/features/tv_show_details/providers/similar_tv_shows_provider.dart';
import 'package:sparrow/navigation/dpad_navigation.dart';
import 'package:sparrow/shared/navigation/tv_show_navigation.dart';
import 'package:sparrow/shared/responsive_utils.dart';
import 'package:sparrow/theme/color_palette.dart';

/// Horizontally scrollable Similar TV Shows carousel reusing [PortraitPosterCard].
class SimilarTvShowsSection extends ConsumerWidget {
  final String seriesId;
  final bool isTvOrDesktop;

  const SimilarTvShowsSection({
    super.key,
    required this.seriesId,
    this.isTvOrDesktop = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsive = context.responsive;
    final similarAsync = ref.watch(similarTvShowsProvider(seriesId));
    final isDesktop = isTvOrDesktop || responsive.isTvOrDesktop;

    final posterWidth = isDesktop
        ? 160.0
        : responsive.scale(125.0, min: 105.0, max: 155.0);
    final carouselHeight = (posterWidth * 1.5) + 20.0;

    return similarAsync.when(
      data: (shows) {
        if (shows.isEmpty) return const SizedBox.shrink();

        Widget list = ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: responsive.scale(12, min: 8, max: 16),
          ),
          itemCount: shows.length,
          itemBuilder: (context, index) {
            final show = shows[index];
            return Padding(
              padding: const EdgeInsets.all(8),
              child: FocusablePosterCard(
                onSelected: () => openTvShowDetails(context, show),
                child: PortraitPosterCard(
                  item: show,
                  width: posterWidth,
                  trending: false,
                  index: index,
                  onTap: () => openTvShowDetails(context, show),
                ),
              ),
            );
          },
        );

        if (isDesktop) {
          list = DpadRegion(leftEdge: DpadEdgeBehavior.leave, child: list);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop
                    ? 0
                    : responsive.scale(16, min: 12, max: 20),
              ),
              child: Row(
                children: [
                  if (!isDesktop) ...[
                    Container(
                      width: 3,
                      height: 18,
                      decoration: BoxDecoration(
                        color: ColorPalette.primaryGreen,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    'You May Also Like',
                    style: TextStyle(
                      color: ColorPalette.fontWhite,
                      fontSize: isDesktop
                          ? 26
                          : responsive.sp(18, min: 15, max: 22),
                      fontWeight: isDesktop ? FontWeight.w800 : FontWeight.w700,
                      letterSpacing: isDesktop ? -0.5 : 0,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Curated Picks',
                    style: TextStyle(
                      color: ColorPalette.textMuted,
                      fontSize: isDesktop
                          ? 12.5
                          : responsive.sp(11, min: 9.5, max: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Horizontal Carousel of Reused Poster Cards
            SizedBox(height: carouselHeight, child: list),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: ColorPalette.primaryGreen,
            ),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
