import 'package:flutter/material.dart';
import 'package:sparrow/features/about_page/data/movie_detail_info.dart';
import 'package:sparrow/shared/responsive_utils.dart';
import 'package:sparrow/theme/color_palette.dart';

/// Renders additional movie information (Director, Writers, Studios, Language, Budget, Revenue).
///
/// Adapts gracefully:
/// - Compact 2-column mobile grid on phones.
/// - Telemetry-rich "Production Matrix" Bento card on TV/Desktop and Tablets.
class MovieInfoMatrix extends StatelessWidget {
  final MovieDetailInfo info;
  final bool isTvOrDesktop;

  const MovieInfoMatrix({
    super.key,
    required this.info,
    this.isTvOrDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final isDesktop = isTvOrDesktop || responsive.isTvOrDesktop;

    if (isDesktop) {
      return _buildProductionMatrixBento(context);
    }
    return _buildMobileInfoGrid(context);
  }

  /// Mobile layout: 2-column card grid with budget/revenue highlight row.
  Widget _buildMobileInfoGrid(BuildContext context) {
    final responsive = context.responsive;
    final cardColor = ColorPalette.surfaceContainer;
    final labelColor = ColorPalette.textMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
              'Movie Information',
              style: TextStyle(
                color: ColorPalette.fontWhite,
                fontSize: responsive.sp(18, min: 15, max: 22),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Grid of details
        Column(
          children: [
            Row(
              children: [
                if (info.director.isNotEmpty)
                  Expanded(
                    child: _buildInfoCard(
                      label: 'DIRECTOR',
                      value: info.director,
                      backgroundColor: cardColor,
                      labelColor: labelColor,
                      responsive: responsive,
                    ),
                  ),
                if (info.director.isNotEmpty &&
                    info.releaseDateFormatted.isNotEmpty)
                  const SizedBox(width: 8),
                if (info.releaseDateFormatted.isNotEmpty)
                  Expanded(
                    child: _buildInfoCard(
                      label: 'RELEASE DATE',
                      value: info.releaseDateFormatted,
                      backgroundColor: cardColor,
                      labelColor: labelColor,
                      responsive: responsive,
                    ),
                  ),
              ],
            ),
            if (info.writers.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoCard(
                label: 'WRITERS',
                value: info.writers,
                backgroundColor: cardColor,
                labelColor: labelColor,
                responsive: responsive,
                isFullWidth: true,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                if (info.studios.isNotEmpty)
                  Expanded(
                    child: _buildInfoCard(
                      label: 'PRODUCTION',
                      value: info.studios,
                      backgroundColor: cardColor,
                      labelColor: labelColor,
                      responsive: responsive,
                    ),
                  ),
                if (info.studios.isNotEmpty && info.originalLanguage.isNotEmpty)
                  const SizedBox(width: 8),
                if (info.originalLanguage.isNotEmpty)
                  Expanded(
                    child: _buildInfoCard(
                      label: 'ORIGINAL LANGUAGE',
                      value: info.originalLanguage,
                      backgroundColor: cardColor,
                      labelColor: labelColor,
                      responsive: responsive,
                    ),
                  ),
              ],
            ),
            if (info.budgetFormatted.isNotEmpty ||
                info.revenueFormatted.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: ColorPalette.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(responsive.radius(12)),
                  border: Border.all(
                    color: ColorPalette.ghostBorder,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BUDGET',
                            style: TextStyle(
                              color: labelColor,
                              fontSize: responsive.sp(9.5, min: 8.5, max: 11),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            info.budgetFormatted,
                            style: TextStyle(
                              color: ColorPalette.fontWhite,
                              fontSize: responsive.sp(13.5, min: 12, max: 15),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: ColorPalette.ghostBorder,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'BOX OFFICE REVENUE',
                            style: TextStyle(
                              color: labelColor,
                              fontSize: responsive.sp(9.5, min: 8.5, max: 11),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            info.revenueFormatted,
                            style: TextStyle(
                              color: ColorPalette.primaryGreen,
                              fontSize: responsive.sp(14, min: 12.5, max: 16),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// TV / Desktop layout: "Production Matrix" Bento Card.
  Widget _buildProductionMatrixBento(BuildContext context) {
    final responsive = context.responsive;

    return Container(
      decoration: BoxDecoration(
        color: ColorPalette.surfaceContainer.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(responsive.radius(18)),
        border: Border.all(color: ColorPalette.ghostBorderLight, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bento Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.tune_rounded,
                    size: 20,
                    color: ColorPalette.primaryGreen,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Production Matrix',
                    style: TextStyle(
                      color: ColorPalette.fontWhite,
                      fontSize: responsive.sp(17, min: 14, max: 20),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ColorPalette.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'ID: TMDB-${info.id}',
                  style: TextStyle(
                    color: ColorPalette.textMuted,
                    fontSize: responsive.sp(10, min: 9, max: 11),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: ColorPalette.ghostBorder, height: 1),
          const SizedBox(height: 16),

          // Bento Items Grid
          Wrap(
            spacing: 20,
            runSpacing: 16,
            children: [
              if (info.director.isNotEmpty)
                _buildBentoItem(
                  label: 'DIRECTOR',
                  value: info.director,
                  responsive: responsive,
                ),
              if (info.releaseDateFormatted.isNotEmpty)
                _buildBentoItem(
                  label: 'THEATRICAL RELEASE',
                  value: info.releaseDateFormatted,
                  responsive: responsive,
                ),
              if (info.writers.isNotEmpty)
                _buildBentoItem(
                  label: 'SCREENPLAY & WRITERS',
                  value: info.writers,
                  responsive: responsive,
                  fullWidth: true,
                ),
              if (info.studios.isNotEmpty)
                _buildBentoItem(
                  label: 'STUDIOS',
                  value: info.studios,
                  responsive: responsive,
                ),
              if (info.originalLanguage.isNotEmpty)
                _buildBentoItem(
                  label: 'ORIGINAL LANGUAGE',
                  value: info.originalLanguage,
                  responsive: responsive,
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Financial Bento Modules
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ColorPalette.surfaceContainerHigh.withValues(
                      alpha: 0.6,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: ColorPalette.ghostBorder,
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ESTIMATED BUDGET',
                        style: TextStyle(
                          color: ColorPalette.textMuted,
                          fontSize: responsive.sp(10, min: 8.5, max: 11),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        info.budgetFormatted,
                        style: TextStyle(
                          color: ColorPalette.fontWhite,
                          fontSize: responsive.sp(15, min: 13, max: 18),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ColorPalette.primaryGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: ColorPalette.primaryGreen.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'WORLDWIDE BOX OFFICE',
                        style: TextStyle(
                          color: ColorPalette.primaryGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        info.revenueFormatted,
                        style: TextStyle(
                          color: ColorPalette.primaryGreen,
                          fontSize: responsive.sp(16, min: 14, max: 20),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBentoItem({
    required String label,
    required String value,
    required SparrowResponsive responsive,
    bool fullWidth = false,
  }) {
    return SizedBox(
      width: fullWidth ? double.infinity : 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: ColorPalette.textMuted,
              fontSize: responsive.sp(9.5, min: 8.5, max: 11),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: ColorPalette.fontWhite,
              fontSize: responsive.sp(13.5, min: 12, max: 15),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String label,
    required String value,
    required Color backgroundColor,
    required Color labelColor,
    required SparrowResponsive responsive,
    bool isFullWidth = false,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(responsive.radius(10)),
        border: Border.all(color: ColorPalette.ghostBorder, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontSize: responsive.sp(9, min: 8, max: 10.5),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: ColorPalette.fontWhite,
              fontSize: responsive.sp(12.5, min: 11, max: 14),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
