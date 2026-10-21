import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparrow/features/tv_show_details/data/tv_season_model.dart';
import 'package:sparrow/features/tv_show_details/providers/tv_seasons_provider.dart';
import 'package:sparrow/navigation/dpad_navigation.dart';
import 'package:sparrow/shared/responsive_utils.dart';
import 'package:sparrow/theme/color_palette.dart';

/// Season selector widget allowing users to toggle between available seasons.
/// Adapts gracefully for mobile compact capsule and TV large-screen pill button.
class TvSeasonSelector extends ConsumerStatefulWidget {
  final String seriesId;
  final List<TvSeasonSummary> seasons;
  final bool isTvOrDesktop;

  const TvSeasonSelector({
    super.key,
    required this.seriesId,
    required this.seasons,
    this.isTvOrDesktop = false,
  });

  @override
  ConsumerState<TvSeasonSelector> createState() => _TvSeasonSelectorState();
}

class _TvSeasonSelectorState extends ConsumerState<TvSeasonSelector> {
  final GlobalKey<PopupMenuButtonState<int>> _popupKey =
      GlobalKey<PopupMenuButtonState<int>>();

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final isDesktop = widget.isTvOrDesktop || responsive.isTvOrDesktop;
    final selectedSeasonNum = ref.watch(selectedSeasonProvider(widget.seriesId));

    // Fallback if seasons list is empty
    if (widget.seasons.isEmpty) {
      return Container(
        height: isDesktop ? 44 : 38,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: ColorPalette.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: ColorPalette.ghostBorder, width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isDesktop) ...[
              const Icon(
                Icons.video_library_rounded,
                size: 18,
                color: ColorPalette.primaryGreen,
              ),
              const SizedBox(width: 8),
            ],
            const Text(
              'Season 1',
              style: TextStyle(
                color: ColorPalette.fontWhite,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // Find current active season or fallback to first
    final currentSeason = widget.seasons.firstWhere(
      (s) => s.seasonNumber == selectedSeasonNum,
      orElse: () => widget.seasons.first,
    );

    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: ColorPalette.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(responsive.radius(14)),
            side: BorderSide(
              color: ColorPalette.primaryGreen.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          elevation: 16,
        ),
      ),
      child: TvFocusable(
        borderRadius: BorderRadius.circular(25),
        onSelect: () => _popupKey.currentState?.showButtonMenu(),
        child: PopupMenuButton<int>(
          key: _popupKey,
          tooltip: 'Select Season',
          initialValue: currentSeason.seasonNumber,
          offset: Offset(0, isDesktop ? 52 : 44),
          constraints: const BoxConstraints(minWidth: 180, maxWidth: 280),
          position: PopupMenuPosition.under,
          onSelected: (int seasonNum) {
            ref
                .read(selectedSeasonMapProvider.notifier)
                .selectSeason(widget.seriesId, seasonNum);
          },
          itemBuilder: (BuildContext context) {
            return widget.seasons.map((TvSeasonSummary season) {
              final isSelected =
                  season.seasonNumber == currentSeason.seasonNumber;
              final yearSuffix = season.airYear.isNotEmpty
                  ? ' (${season.airYear})'
                  : '';

              return PopupMenuItem<int>(
                value: season.seasonNumber,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ColorPalette.primaryGreen.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(
                            color: ColorPalette.primaryGreen.withValues(
                              alpha: 0.4,
                            ),
                            width: 1,
                          )
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          '${season.name}$yearSuffix',
                          softWrap: true,
                          style: TextStyle(
                            color: isSelected
                                ? ColorPalette.primaryGreen
                                : ColorPalette.fontWhite,
                            fontSize: isDesktop ? 14 : 12.5,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: ColorPalette.primaryGreen,
                        ),
                    ],
                  ),
                ),
              );
            }).toList();
          },
          child: Container(
            height: isDesktop ? 44 : 38,
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 16 : 14),
            decoration: BoxDecoration(
              color: ColorPalette.surfaceContainerHigh.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: ColorPalette.ghostBorderLight,
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isDesktop) ...[
                  const Icon(
                    Icons.video_library_rounded,
                    size: 18,
                    color: ColorPalette.primaryGreen,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  currentSeason.name,
                  style: TextStyle(
                    color: ColorPalette.fontWhite,
                    fontSize: isDesktop ? 14 : 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: ColorPalette.primaryGreen,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
