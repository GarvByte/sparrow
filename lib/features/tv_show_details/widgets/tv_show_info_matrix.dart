import 'package:flutter/material.dart';
import 'package:sparrow/features/tv_show_details/data/tv_show_detail_info.dart';
import 'package:sparrow/shared/responsive_utils.dart';
import 'package:sparrow/theme/color_palette.dart';

/// Renders the "About [Show]" telemetry section.
/// Adapts gracefully:
/// - 2-column mobile card on phones.
/// - 4-column Bento grid on TV and large desktop screens.
class TvShowInfoMatrix extends StatelessWidget {
  final TvShowDetailInfo info;
  final bool isTvOrDesktop;

  const TvShowInfoMatrix({
    super.key,
    required this.info,
    this.isTvOrDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final isDesktop = isTvOrDesktop || responsive.isTvOrDesktop;

    if (isDesktop) {
      return _buildTvBentoGrid(context);
    }
    return _buildMobileGrid(context);
  }

  /// Mobile layout: 2-column telemetry card matching mobile Stitch design.
  Widget _buildMobileGrid(BuildContext context) {
    final responsive = context.responsive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
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
              'About ${info.name}',
              style: TextStyle(
                color: ColorPalette.fontWhite,
                fontSize: responsive.sp(18, min: 15, max: 22),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: ColorPalette.primaryGreen,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Information Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ColorPalette.surfaceContainerLow,
            borderRadius: BorderRadius.circular(responsive.radius(16)),
            border: Border.all(color: ColorPalette.ghostBorder, width: 0.8),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildCell(
                      label: 'CREATOR',
                      value: info.creators.isNotEmpty ? info.creators : 'Various',
                      responsive: responsive,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCell(
                      label: 'STATUS',
                      value: info.status,
                      isAccent: true,
                      responsive: responsive,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildCell(
                      label: 'FIRST AIRED',
                      value: info.firstAirDateFormatted.isNotEmpty
                          ? info.firstAirDateFormatted
                          : info.firstAirYear,
                      responsive: responsive,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCell(
                      label: 'LAST AIRED',
                      value: info.lastAirDateFormatted.isNotEmpty
                          ? info.lastAirDateFormatted
                          : (info.lastAirYear.isNotEmpty ? info.lastAirYear : 'Present'),
                      responsive: responsive,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildCell(
                      label: 'SEASONS',
                      value: info.seasonsFormatted,
                      responsive: responsive,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCell(
                      label: 'TOTAL EPISODES',
                      value: info.episodesFormatted.isNotEmpty
                          ? info.episodesFormatted
                          : '${info.numberOfEpisodes} Episodes',
                      responsive: responsive,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(color: ColorPalette.ghostBorder, height: 1),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: _buildCell(
                  label: 'ORIGINAL LANGUAGE',
                  value: info.originalLanguage,
                  responsive: responsive,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// TV layout: 4-column Bento grid matching TV Stitch design.
  Widget _buildTvBentoGrid(BuildContext context) {
    final responsive = context.responsive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'About ${info.name}',
              style: const TextStyle(
                color: ColorPalette.fontWhite,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: ColorPalette.surfaceContainerLow,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'PRODUCTION METADATA',
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
        const SizedBox(height: 18),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tile 1: Creator & Studio
            Expanded(
              child: _buildTvBentoTile(
                label: 'CREATOR',
                title: info.creators.isNotEmpty ? info.creators : 'Show Creators',
                subtitle: info.studios.isNotEmpty ? info.studios : 'Television Production',
                responsive: responsive,
              ),
            ),
            const SizedBox(width: 16),

            // Tile 2: Original Broadcast
            Expanded(
              child: _buildTvBentoTile(
                label: 'ORIGINAL BROADCAST',
                title: info.firstAirDateFormatted.isNotEmpty
                    ? 'Premiere: ${info.firstAirDateFormatted}'
                    : info.firstAirYear,
                subtitle: info.lastAirDateFormatted.isNotEmpty
                    ? 'Finale: ${info.lastAirDateFormatted}'
                    : (info.lastAirYear.isNotEmpty ? 'Finale: ${info.lastAirYear}' : 'Ongoing'),
                responsive: responsive,
              ),
            ),
            const SizedBox(width: 16),

            // Tile 3: Seasons & Episodes
            Expanded(
              child: _buildTvBentoTile(
                label: 'SEASONS & EPISODES',
                title: '${info.seasonsFormatted} · ${info.episodesFormatted}',
                subtitle: info.runtimeFormatted.isNotEmpty
                    ? 'Avg Runtime: ${info.runtimeFormatted}'
                    : 'Full Episodic Catalog',
                responsive: responsive,
              ),
            ),
            const SizedBox(width: 16),

            // Tile 4: Language & Status
            Expanded(
              child: _buildTvBentoTile(
                label: 'LANGUAGE & STATUS',
                title: info.originalLanguage,
                subtitle: info.status,
                isAccentSubtitle: true,
                responsive: responsive,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCell({
    required String label,
    required String value,
    bool isAccent = false,
    required SparrowResponsive responsive,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: ColorPalette.textMuted,
            fontSize: responsive.sp(10, min: 8.5, max: 11.5),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isAccent ? ColorPalette.primaryGreen : ColorPalette.fontWhite,
            fontSize: responsive.sp(13.5, min: 12, max: 15),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildTvBentoTile({
    required String label,
    required String title,
    required String subtitle,
    bool isAccentSubtitle = false,
    required SparrowResponsive responsive,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ColorPalette.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorPalette.ghostBorderLight, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: ColorPalette.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ColorPalette.fontWhite,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isAccentSubtitle ? ColorPalette.primaryGreen : ColorPalette.textMuted,
              fontSize: 12.5,
              fontWeight: isAccentSubtitle ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
