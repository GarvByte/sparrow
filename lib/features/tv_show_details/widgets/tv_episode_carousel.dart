import 'package:dpad/dpad.dart';
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

    Widget content;
    // 1. Render existing data whenever available (even during background refresh)
    if (seasonDetailAsync.hasValue &&
        seasonDetailAsync.value != null &&
        seasonDetailAsync.value!.episodes.isNotEmpty) {
      final episodes = seasonDetailAsync.value!.episodes;
      content = SizedBox(
        height: 290,
        child: DpadRegion(
          leftEdge: DpadEdgeBehavior.leave,
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
        ),
      );
    } else if (seasonDetailAsync.isLoading) {
      // 2. Initial loading
      content = Container(
        height: 260,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          color: ColorPalette.primaryGreen,
        ),
      );
    } else if (seasonDetailAsync.hasError) {
      // 3. Error with retry
      content = Container(
        height: 220,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ColorPalette.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 20, color: ColorPalette.textMuted),
            const Text(
              'Unable to load episodes',
              style: TextStyle(color: ColorPalette.textMuted, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            TextButton(
              onPressed: () => ref.refresh(tvSeasonDetailProvider(query)),
              child: const Text('Retry',
                  style: TextStyle(color: ColorPalette.primaryGreen)),
            ),
          ],
        ),
      );
    } else {
      // 4. Genuinely empty
      content = Container(
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

        content,
      ],
    );
  }
}
