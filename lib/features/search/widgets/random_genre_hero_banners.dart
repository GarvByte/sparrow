import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparrow/features/search/providers/search_genre_banners_provider.dart';
import 'package:sparrow/features/search/widgets/sparrow_masters_card.dart';
import 'package:sparrow/shared/media_item.dart';
import 'package:sparrow/shared/responsive_utils.dart';
import 'package:sparrow/theme/color_palette.dart';

class RandomGenreHeroBanners extends ConsumerWidget {
  final ValueChanged<MediaItem>? onMovieTap;

  const RandomGenreHeroBanners({super.key, this.onMovieTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsive = context.responsive;
    final sectionAsync = ref.watch(searchGenreBannersProvider);

    return sectionAsync.when(
      data: (section) {
        if (section.movies.isEmpty) return const SizedBox.shrink();

        final headingText = '${section.genreName} Movies';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: responsive.scale(24, min: 18, max: 30)),

            // Section Header with Emerald Dot and Selected Genre Name
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.scale(16, min: 12, max: 20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: ColorPalette.primaryGreen,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: ColorPalette.primaryGreen.withValues(
                            alpha: 0.8,
                          ),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    headingText,
                    style: TextStyle(
                      color: ColorPalette.fontWhite,
                      fontSize: responsive.sp(18, min: 15, max: 21),
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Vertical list of ALL valid hero banner cards from Page 1 of this genre
            ...section.movies.map((movie) {
              return Padding(
                padding: EdgeInsets.only(
                  left: responsive.scale(16, min: 12, max: 20),
                  right: responsive.scale(16, min: 12, max: 20),
                  bottom: responsive.scale(18, min: 14, max: 24),
                ),
                child: MasterShowcase(
                  movie: movie,
                  badgeText: section.genreName.toUpperCase(),
                  onPlayTap: () => onMovieTap?.call(movie),
                  onTap: () => onMovieTap?.call(movie),
                ),
              );
            }),
          ],
        );
      },
      loading: () => Padding(
        padding: EdgeInsets.symmetric(
          horizontal: responsive.scale(16, min: 12, max: 20),
          vertical: 24,
        ),
        child: Container(
          height: 220,
          decoration: BoxDecoration(
            color: ColorPalette.surfaceContainer,
            borderRadius: BorderRadius.circular(responsive.radius(16)),
          ),
          child: const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: ColorPalette.primaryGreen,
              ),
            ),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
