import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparrow/features/tv_show_details/data/tv_season_model.dart';
import 'package:sparrow/features/tv_show_details/providers/tv_seasons_provider.dart';
import 'package:sparrow/features/tv_show_details/widgets/tv_episode_card.dart';
import 'package:sparrow/features/tv_show_details/widgets/tv_season_selector.dart';
import 'package:sparrow/shared/responsive_utils.dart';
import 'package:sparrow/theme/color_palette.dart';

/// Vertically scrolling episode list for mobile and tablet views.
class TvEpisodeList extends ConsumerStatefulWidget {
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
  ConsumerState<TvEpisodeList> createState() => _TvEpisodeListState();
}

class _TvEpisodeListState extends ConsumerState<TvEpisodeList> {
  int _visibleCount = 30;
  String? _lastSeriesId;
  int? _lastSeasonNum;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final selectedSeasonNum = ref.watch(selectedSeasonProvider(widget.seriesId));

    if (_lastSeriesId != widget.seriesId ||
        _lastSeasonNum != selectedSeasonNum) {
      _lastSeriesId = widget.seriesId;
      _lastSeasonNum = selectedSeasonNum;
      _visibleCount = 30;
    }

    final query = TvSeasonQuery(
      seriesId: widget.seriesId,
      seasonNumber: selectedSeasonNum,
    );
    final seasonDetailAsync = ref.watch(tvSeasonDetailProvider(query));

    Widget content;
    // 1. Render existing data whenever available (even during background refresh)
    if (seasonDetailAsync.hasValue &&
        seasonDetailAsync.value != null &&
        seasonDetailAsync.value!.episodes.isNotEmpty) {
      final episodes = seasonDetailAsync.value!.episodes;
      final displayedCount = _visibleCount.clamp(0, episodes.length);
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayedCount,
            separatorBuilder: (context, index) => const Divider(
              color: ColorPalette.ghostBorder,
              height: 16,
              thickness: 0.8,
            ),
            itemBuilder: (context, index) {
              final episode = episodes[index];
              return TvEpisodeCard(
                episode: episode,
                seriesId: widget.seriesId,
                isTvLayout: false,
                onPlay: () => widget.onEpisodeSelected?.call(episode),
              );
            },
          ),
          if (displayedCount < episodes.length)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorPalette.primaryGreen,
                    side: const BorderSide(
                      color: ColorPalette.primaryGreen,
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _visibleCount += 50;
                    });
                  },
                  icon: const Icon(Icons.expand_more_rounded, size: 20),
                  label: Text(
                    'Load More Episodes ($displayedCount of ${episodes.length})',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    } else if (seasonDetailAsync.isLoading) {
      // 2. Initial loading
      content = Container(
        padding: const EdgeInsets.symmetric(vertical: 36),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          color: ColorPalette.primaryGreen,
        ),
      );
    } else if (seasonDetailAsync.hasError) {
      // 3. Error with retry
      content = Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        alignment: Alignment.center,
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Text(
              'Unable to load episodes',
              style: TextStyle(
                color: ColorPalette.textMuted,
                fontSize: responsive.sp(13, min: 11, max: 15),
              ),
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
              seriesId: widget.seriesId,
              seasons: widget.seasons,
              isTvOrDesktop: false,
            ),
          ],
        ),
        const SizedBox(height: 12),

        content,
      ],
    );
  }
}
