import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparrow/features/tv_show_details/data/tv_season_model.dart';
import 'package:sparrow/features/tv_show_details/providers/tv_seasons_provider.dart';
import 'package:sparrow/features/tv_show_details/widgets/tv_episode_card.dart';
import 'package:sparrow/features/tv_show_details/widgets/tv_season_selector.dart';
import 'package:sparrow/shared/responsive_utils.dart';
import 'package:sparrow/theme/color_palette.dart';

/// Vertically scrolling episode list for mobile and tablet views.
class TvEpisodeList extends ConsumerWidget {
  final String seriesId;
  final List<TvSeasonSummary> seasons;
  final void Function(TvEpisodeInfo episode)? onEpisodeSelected;

  const TvEpisodeList({
    super.key,
    required this.seriesId,
    required this.seasons,
    this.onEpisodeSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsive = context.responsive;
    final selectedSeasonNum = ref.watch(selectedSeasonProvider(seriesId));

    final query = TvSeasonQuery(
      seriesId: seriesId,
      seasonNumber: selectedSeasonNum,
    );
    final seasonDetailAsync = ref.watch(tvSeasonDetailProvider(query));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header & Season Selector
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
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
                  'Episodes',
                  style: TextStyle(
                    color: ColorPalette.fontWhite,
                    fontSize: responsive.sp(18, min: 15, max: 22),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            TvSeasonSelector(
              seriesId: seriesId,
              seasons: seasons,
              isTvOrDesktop: false,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Episodes content
        seasonDetailAsync.when(
          data: (seasonDetail) {
            final episodes = seasonDetail?.episodes ?? [];

            if (episodes.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                alignment: Alignment.center,
                child: Text(
                  'No episodes available for this season.',
                  style: TextStyle(
                    color: ColorPalette.textMuted,
                    fontSize: responsive.sp(13, min: 11, max: 15),
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: episodes.length,
              separatorBuilder: (context, index) => const Divider(
                color: ColorPalette.ghostBorder,
                height: 16,
                thickness: 0.8,
              ),
              itemBuilder: (context, index) {
                final episode = episodes[index];
                return TvEpisodeCard(
                  episode: episode,
                  seriesId: seriesId,
                  isTvLayout: false,
                  onPlay: () => onEpisodeSelected?.call(episode),
                );
              },
            );
          },
          loading: () => Container(
            padding: const EdgeInsets.symmetric(vertical: 36),
            alignment: Alignment.center,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              color: ColorPalette.primaryGreen,
            ),
          ),
          error: (error, _) => Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            alignment: Alignment.center,
            child: Text(
              'Unable to load episodes. Please try again.',
              style: TextStyle(
                color: ColorPalette.textMuted,
                fontSize: responsive.sp(13, min: 11, max: 15),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
