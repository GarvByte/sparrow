import 'package:cached_network_image/cached_network_image.dart';
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:sparrow/features/tv_show_details/data/tv_season_model.dart';
import 'package:sparrow/shared/error_image_placeholder.dart';
import 'package:sparrow/shared/responsive_utils.dart';
import 'package:sparrow/theme/color_palette.dart';

/// Single episode presentation card.
/// Supports compact mobile layout (horizontal thumb + title, overview below)
/// and large TV layout (16:9 cinematic card with play affordance and metadata below).
class TvEpisodeCard extends StatelessWidget {
  final TvEpisodeInfo episode;
  final String seriesId;
  final bool isTvLayout;
  final VoidCallback? onPlay;

  const TvEpisodeCard({
    super.key,
    required this.episode,
    required this.seriesId,
    this.isTvLayout = false,
    this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    if (isTvLayout) {
      return _buildTvCard(context);
    }
    return _buildMobileCard(context);
  }

  /// Mobile layout: horizontal thumbnail + title and runtime, with synopsis below.
  Widget _buildMobileCard(BuildContext context) {
    final responsive = context.responsive;
    final thumbWidth = responsive.scale(136.0, min: 110.0, max: 155.0);

    return InkWell(
      onTap: onPlay,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 16:9 Landscape Thumbnail with Play Affordance
                Container(
                  width: thumbWidth,
                  height: thumbWidth * 9 / 16,
                  decoration: BoxDecoration(
                    color: ColorPalette.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: ColorPalette.ghostBorder,
                      width: 0.8,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (episode.stillUrl.isNotEmpty)
                          CachedNetworkImage(
                            imageUrl: episode.stillUrl,
                            fit: BoxFit.cover,
                            fadeInDuration: const Duration(milliseconds: 200),
                            fadeOutDuration: const Duration(milliseconds: 200),
                            placeholder: (context, url) => Container(
                              color: ColorPalette.surfaceContainerLow,
                            ),
                            errorWidget: (context, url, error) =>
                                const ErrorImagePlaceholder(),
                          )
                        else
                          const ErrorImagePlaceholder(),

                        // Gradient Scrim
                        Container(color: Colors.black.withValues(alpha: 0.25)),

                        // Centered Play Button
                        Center(
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: ColorPalette.backgroundBlack.withValues(
                                alpha: 0.8,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: ColorPalette.primaryGreen.withValues(
                                  alpha: 0.5,
                                ),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              size: 20,
                              color: ColorPalette.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Title & Runtime
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        episode.episodeLabel,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ColorPalette.fontWhite,
                          fontSize: responsive.sp(14, min: 12.5, max: 16),
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (episode.runtimeFormatted.isNotEmpty)
                        Text(
                          episode.runtimeFormatted,
                          style: TextStyle(
                            color: ColorPalette.textMuted,
                            fontSize: responsive.sp(11.5, min: 10, max: 13),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (episode.overview.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                episode.overview,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ColorPalette.textMuted,
                  fontSize: responsive.sp(12, min: 10.5, max: 13.5),
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// TV layout: 16:9 large landscape card with thumbnail, play circle, title and overview below.
  Widget _buildTvCard(BuildContext context) {
    const cardWidth = 320.0;
    const thumbHeight = cardWidth * 9 / 16;

    final card = Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        // padding: EdgeInsets.all(8),
        width: cardWidth,
        decoration: BoxDecoration(
          color: ColorPalette.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ColorPalette.ghostBorderLight, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPlay,
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 16:9 Thumbnail Header
                SizedBox(
                  width: cardWidth,
                  height: thumbHeight,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (episode.stillUrl.isNotEmpty)
                          CachedNetworkImage(
                            imageUrl: episode.stillUrl,
                            fit: BoxFit.cover,
                            fadeInDuration: const Duration(milliseconds: 200),
                            fadeOutDuration: const Duration(milliseconds: 200),
                            placeholder: (context, url) => Container(
                              color: ColorPalette.surfaceContainerLow,
                            ),
                            errorWidget: (context, url, error) =>
                                const ErrorImagePlaceholder(),
                          )
                        else
                          const ErrorImagePlaceholder(),

                        // Gradient Scrim
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                ColorPalette.backgroundBlack.withValues(
                                  alpha: 0.7,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Centered Play Button
                        Center(
                          child: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: ColorPalette.primaryGreen,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: ColorPalette.primaryGreen.withValues(
                                    alpha: 0.4,
                                  ),
                                  blurRadius: 14,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              size: 28,
                              color: Colors.black,
                            ),
                          ),
                        ),

                        // Runtime Pill bottom right
                        if (episode.runtimeFormatted.isNotEmpty)
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: ColorPalette.backgroundBlack.withValues(
                                  alpha: 0.85,
                                ),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: ColorPalette.ghostBorder,
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                episode.runtimeFormatted,
                                style: const TextStyle(
                                  color: ColorPalette.fontWhite,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),

                        // Episode Number Pill top left
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: ColorPalette.backgroundBlack.withValues(
                                alpha: 0.85,
                              ),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: ColorPalette.primaryGreen.withValues(
                                  alpha: 0.5,
                                ),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              'EP ${episode.episodeNumber}',
                              style: const TextStyle(
                                color: ColorPalette.primaryGreen,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Metadata Body
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        episode.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ColorPalette.fontWhite,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        episode.overview.isNotEmpty
                            ? episode.overview
                            : 'No episode synopsis provided.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ColorPalette.textMuted,
                          fontSize: 12.5,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return DpadFocusable(
      effects: [
        DpadBorderEffect(
          width: 3,
          color: ColorPalette.primaryGreen,
          borderRadius: BorderRadius.circular(16),
        ),
        DpadTintEffect(color: ColorPalette.fontWhite, opacity: 0.2),
      ],
      onSelect: () => onPlay?.call(),
      child: card,
    );
  }
}
