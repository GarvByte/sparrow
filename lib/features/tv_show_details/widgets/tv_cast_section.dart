import 'package:cached_network_image/cached_network_image.dart';
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparrow/features/tv_show_details/data/tv_cast_member.dart';
import 'package:sparrow/features/tv_show_details/providers/tv_credits_provider.dart';
import 'package:sparrow/shared/responsive_utils.dart';
import 'package:sparrow/theme/color_palette.dart';

/// Horizontally scrollable TV Show Cast & Crew section.
class TvCastSection extends ConsumerWidget {
  final String seriesId;
  final bool isTvOrDesktop;

  const TvCastSection({
    super.key,
    required this.seriesId,
    this.isTvOrDesktop = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsive = context.responsive;
    final creditsAsync = ref.watch(tvCreditsProvider(seriesId));
    final isDesktop = isTvOrDesktop || responsive.isTvOrDesktop;

    final avatarSize = isDesktop
        ? 96.0
        : responsive.scale(64.0, min: 54.0, max: 76.0);
    final itemWidth = isDesktop
        ? 120.0
        : responsive.scale(80.0, min: 70.0, max: 96.0);

    // 1. Render existing data whenever available (even during background refresh)
    if (creditsAsync.hasValue &&
        creditsAsync.value != null &&
        creditsAsync.value!.isNotEmpty) {
      final castList = creditsAsync.value!;
      Widget list = ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop
              ? 0
              : responsive.scale(16, min: 12, max: 20),
        ),
        itemCount: castList.length,
        separatorBuilder: (context, index) =>
            SizedBox(width: isDesktop ? 20 : 12),
        itemBuilder: (context, index) {
          final actor = castList[index];
          return _TvCastCard(
            actor: actor,
            width: itemWidth,
            avatarSize: avatarSize,
          );
        },
      );

      if (isDesktop) {
        list = DpadRegion(
          leftEdge: DpadEdgeBehavior.leave,
          child: list,
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop
                  ? 0
                  : responsive.scale(16, min: 12, max: 20),
            ),
            child: Row(
              children: [
                if (!isDesktop) ...[
                  Container(
                    width: 3,
                    height: 18,
                    decoration: BoxDecoration(
                      color: ColorPalette.primaryGreen,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  'Cast & Crew',
                  style: TextStyle(
                    color: ColorPalette.fontWhite,
                    fontSize: isDesktop
                        ? 26
                        : responsive.sp(18, min: 15, max: 22),
                    fontWeight: isDesktop ? FontWeight.w800 : FontWeight.w700,
                    letterSpacing: isDesktop ? -0.5 : 0,
                  ),
                ),
                const Spacer(),
                Text(
                  '${castList.length} Actors',
                  style: TextStyle(
                    color: ColorPalette.textMuted,
                    fontSize: isDesktop ? 12.5 : responsive.sp(11, min: 9.5, max: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Horizontal Scrollable Avatars
          SizedBox(
            height: avatarSize + 52,
            child: list,
          ),
        ],
      );
    }

    // 2. Initial loading state
    if (creditsAsync.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
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

    // 3. Error state with retry
    if (creditsAsync.hasError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                'Could not load cast details',
                style: TextStyle(
                  color: ColorPalette.textMuted,
                  fontSize: responsive.sp(12, min: 10, max: 14),
                ),
                textAlign: TextAlign.center,
              ),
              TextButton(
                onPressed: () => ref.refresh(tvCreditsProvider(seriesId)),
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

    // 4. Genuinely empty
    return const SizedBox.shrink();
  }
}

class _TvCastCard extends StatelessWidget {
  final TvCastMember actor;
  final double width;
  final double avatarSize;

  const _TvCastCard({
    required this.actor,
    required this.width,
    required this.avatarSize,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: ColorPalette.primaryGreen.withValues(alpha: 0.35),
                width: 1.5,
              ),
              color: ColorPalette.surfaceContainerHigh,
            ),
            child: ClipOval(
              child: actor.profileUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: actor.profileUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: ColorPalette.surfaceContainerHighest,
                        child: const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: ColorPalette.primaryGreen,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.person_rounded,
                        color: ColorPalette.textMuted,
                        size: 28,
                      ),
                    )
                  : const Icon(
                      Icons.person_rounded,
                      color: ColorPalette.textMuted,
                      size: 28,
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            actor.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ColorPalette.fontWhite,
              fontSize: responsive.sp(12, min: 10.5, max: 13.5),
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            actor.character.isNotEmpty ? actor.character : 'Cast',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ColorPalette.textMuted,
              fontSize: responsive.sp(10.5, min: 9, max: 11.5),
            ),
          ),
        ],
      ),
    );
  }
}
