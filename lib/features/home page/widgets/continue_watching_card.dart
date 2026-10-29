import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sparrow/navigation/dpad_navigation.dart';
import 'package:sparrow/shared/error_image_placeholder.dart';
import '../../../shared/responsive_utils.dart';
import '../../../theme/color_palette.dart';
import '../../../shared/media_item.dart';

class ContinueWatchingCard extends StatefulWidget {
  final MediaItem item;
  final double? width;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const ContinueWatchingCard({
    super.key,
    required this.item,
    this.width,
    this.onTap,
    this.onRemove,
  });

  @override
  State<ContinueWatchingCard> createState() => _ContinueWatchingCardState();
}

class _ContinueWatchingCardState extends State<ContinueWatchingCard> {
  late final FocusNode _cardFocusNode;
  late final FocusNode _closeFocusNode;

  @override
  void initState() {
    super.initState();
    _cardFocusNode = FocusNode(debugLabel: 'continue_card_${widget.item.id}');
    _closeFocusNode = FocusNode(debugLabel: 'continue_close_${widget.item.id}');
  }

  @override
  void dispose() {
    _cardFocusNode.dispose();
    _closeFocusNode.dispose();
    super.dispose();
  }

  void _handleRemove() {
    if (context.responsive.isTvOrDesktop) {
      if (_closeFocusNode.hasPrimaryFocus || _cardFocusNode.hasFocus) {
        final scope = FocusScope.of(context);
        final moved = scope.focusInDirection(TraversalDirection.right);
        if (!moved) {
          scope.focusInDirection(TraversalDirection.left);
        }
      }
    }
    widget.onRemove?.call();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final cardWidth = widget.width ?? responsive.continueWatchingWidth;
    final cardHeight = cardWidth * (9 / 16);

    final cardContent = Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(responsive.radius(16)),
        border: Border.all(color: ColorPalette.ghostBorder, width: 0.8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(responsive.radius(16)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Media Image
            CachedNetworkImage(
              imageUrl: widget.item.imageUrl,
              fit: BoxFit.cover,
              memCacheWidth: 360,
              fadeInDuration: const Duration(milliseconds: 200),
              fadeOutDuration: const Duration(milliseconds: 200),
              errorWidget: (context, url, error) => const ErrorImagePlaceholder(),
              placeholder: (context, url) => Container(
                color: ColorPalette.surfaceContainerLow,
              ),
            ),

            // Subtle Dim Overlay
            Container(color: Colors.black.withValues(alpha: 0.35)),

            // Center Circular Play Button
            Center(
              child: Container(
                width: responsive.scale(42, min: 36, max: 48),
                height: responsive.scale(42, min: 36, max: 48),
                decoration: BoxDecoration(
                  color: ColorPalette.surfaceContainerHighest.withValues(
                    alpha: 0.9,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.play_arrow_rounded,
                    size: responsive.iconSize(26, min: 22, max: 30),
                    color: ColorPalette.primaryGreen,
                  ),
                ),
              ),
            ),

            // Time Left Badge (Left-aligned if remove button present, else Right-aligned)
            if (widget.item.durationLeft != null)
              Positioned(
                top: 10,
                left: widget.onRemove != null ? 10 : null,
                right: widget.onRemove != null ? null : 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: ColorPalette.ghostBorder,
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    widget.item.durationLeft!,
                    style: TextStyle(
                      color: ColorPalette.fontWhite,
                      fontSize: responsive.sp(10, min: 8.5, max: 11),
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),

            // Docked Bottom Progress Bar
            if (widget.item.progress != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 3.5,
                  color: ColorPalette.surfaceContainerHighest,
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: widget.item.progress!.clamp(0.0, 1.0),
                    child: Container(color: ColorPalette.primaryGreen),
                  ),
                ),
              ),

            Positioned.fill(
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: widget.onTap,
                  splashColor: ColorPalette.fontWhite.withValues(
                    alpha: 0.35,
                  ),
                  highlightColor: ColorPalette.primaryGreen.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(
                    responsive.radius(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        width: cardWidth,
        height: cardHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: FocusablePosterCard(
                focusNode: _cardFocusNode,
                onSelected: widget.onTap ?? () {},
                onDirection: (direction) {
                  if (direction == TraversalDirection.up && widget.onRemove != null) {
                    _closeFocusNode.requestFocus();
                    return true;
                  }
                  return false;
                },
                borderRadius: BorderRadius.circular(responsive.radius(16)),
                child: cardContent,
              ),
            ),

            // Top-Right Remove Button Overlay
            if (widget.onRemove != null)
              Positioned(
                top: 8,
                right: 8,
                child: TvFocusable(
                  focusNode: _closeFocusNode,
                  onSelect: _handleRemove,
                  onDirection: (direction) {
                    if (direction == TraversalDirection.down ||
                        direction == TraversalDirection.left) {
                      _cardFocusNode.requestFocus();
                      return true;
                    }
                    return false;
                  },
                  focusColor: Colors.redAccent,
                  borderRadius: BorderRadius.circular(16),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onRemove,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: responsive.scale(30, min: 26, max: 34),
                        height: responsive.scale(30, min: 26, max: 34),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: ColorPalette.ghostBorder,
                            width: 0.8,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.close_rounded,
                            size: responsive.iconSize(16, min: 14, max: 18),
                            color: ColorPalette.fontWhite,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
