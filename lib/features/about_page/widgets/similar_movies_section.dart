import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparrow/features/about_page/providers/similar_movies_provider.dart';
import 'package:sparrow/features/home%20page/widgets/portrait_poster_card.dart';
import 'package:sparrow/navigation/dpad_navigation.dart';
import 'package:sparrow/shared/navigation/movie_navigation.dart';
import 'package:sparrow/shared/responsive_utils.dart';
import 'package:sparrow/theme/color_palette.dart';

/// Horizontally scrollable Similar Movies carousel reusing the existing [PortraitPosterCard].
class SimilarMoviesSection extends ConsumerWidget {
  final String movieId;
  final bool isTvOrDesktop;

  const SimilarMoviesSection({
    super.key,
    required this.movieId,
    this.isTvOrDesktop = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsive = context.responsive;
    final similarAsync = ref.watch(similarMoviesProvider(movieId));
    final isDesktop = isTvOrDesktop || responsive.isTvOrDesktop;

    final posterWidth = isDesktop
        ? 160.0
        : responsive.scale(125.0, min: 105.0, max: 155.0);
    // PortraitPosterCard has height = width * 1.5 with 8dp surrounding padding
    final carouselHeight = (posterWidth * 1.5) + 20.0;

    // 1. Render existing data whenever available (even during background refresh)
    if (similarAsync.hasValue &&
        similarAsync.value != null &&
        similarAsync.value!.isNotEmpty) {
      final movies = similarAsync.value!;
      Widget list = ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: responsive.scale(12, min: 8, max: 16),
        ),
        itemCount: movies.length,
        itemBuilder: (context, index) {
          final movie = movies[index];
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: FocusablePosterCard(
              onSelected: () => openMovieDetails(context, movie),
              child: PortraitPosterCard(
                item: movie,
                width: posterWidth,
                trending: false,
                index: index,
                onTap: () => openMovieDetails(context, movie),
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
              horizontal: responsive.scale(16, min: 12, max: 20),
            ),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 18,
                  decoration: BoxDecoration(
                    color: ColorPalette.primaryGreen,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Similar Movies',
                  style: TextStyle(
                    color: ColorPalette.fontWhite,
                    fontSize: responsive.sp(18, min: 15, max: 22),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  'Recommended',
                  style: TextStyle(
                    color: ColorPalette.textMuted,
                    fontSize: responsive.sp(11, min: 9.5, max: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Horizontal Carousel of Reused Poster Cards
          SizedBox(height: carouselHeight, child: list),
        ],
      );
    }

    // 2. Initial loading state (no cached data available)
    if (similarAsync.isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
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
      );
    }

    // 3. Error state when no data exists: show retry control
    if (similarAsync.hasError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                'Could not load similar movies',
                style: TextStyle(
                  color: ColorPalette.textMuted,
                  fontSize: responsive.sp(12, min: 10, max: 14),
                ),
                textAlign: TextAlign.center,
              ),
              TextButton(
                onPressed: () => ref.refresh(similarMoviesProvider(movieId)),
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

    // 4. Genuinely successful empty result
    return const SizedBox.shrink();
  }
}
