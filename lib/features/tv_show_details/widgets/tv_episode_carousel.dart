import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparrow/features/tv_show_details/data/tv_season_model.dart';
import 'package:sparrow/features/tv_show_details/providers/tv_seasons_provider.dart';
import 'package:sparrow/features/tv_show_details/widgets/tv_episode_card.dart';
import 'package:sparrow/features/tv_show_details/widgets/tv_season_selector.dart';
import 'package:sparrow/theme/color_palette.dart';

/// Horizontally scrolling episode carousel for TV and large desktop screens.
class TvEpisodeCarousel extends ConsumerWidget {
  final String seriesId;
  final List<TvSeasonSummary> seasons;
  final void Function(TvEpisodeInfo episode)? onEpisodeSelected;

  const TvEpisodeCarousel({
    super.key,
    required this.seriesId,
    required this.seasons,
    this.onEpisodeSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSeasonNum = ref.watch(selectedSeasonProvider(seriesId));

    final query = TvSeasonQuery(
      seriesId: seriesId,
      seasonNumber: selectedSeasonNum,
    );
    final seasonDetailAsync = ref.watch(tvSeasonDetailProvider(query));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row with Season Selector
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'Episodes',
                  style: TextStyle(
                    color: ColorPalette.fontWhite,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 20),
                TvSeasonSelector(
                  seriesId: seriesId,
                  seasons: seasons,
                  isTvOrDesktop: true,
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: ColorPalette.surfaceContainerLow,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'BROWSE EPISODES',
                style: TextStyle(
                  color: ColorPalette.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 16:9 Landscape Horizontal Carousel
        seasonDetailAsync.when(
          data: (seasonDetail) {
            final episodes = seasonDetail?.episodes ?? [];

            if (episodes.isEmpty) {
              return Container(
                height: 220,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ColorPalette.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ColorPalette.ghostBorder, width: 0.8),
                ),
                child: const Text(
                  'No episodes available for this season.',
                  style: TextStyle(color: ColorPalette.textMuted, fontSize: 15),
                ),
              );
            }

            // Height to accommodate 16:9 thumbnail + title and 2 lines overview + padding (~290px)
            return SizedBox(
              height: 290,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: episodes.length,
                itemBuilder: (context, index) {
                  final episode = episodes[index];
                  return TvEpisodeCard(
                    episode: episode,
                    seriesId: seriesId,
                    isTvLayout: true,
                    onPlay: () => onEpisodeSelected?.call(episode),
                  );
                },
              ),
            );
          },
          loading: () => Container(
            height: 260,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              color: ColorPalette.primaryGreen,
            ),
          ),
          error: (error, _) => Container(
            height: 220,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ColorPalette.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Unable to load episodes. Please try again.',
              style: TextStyle(color: ColorPalette.textMuted, fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }
}
