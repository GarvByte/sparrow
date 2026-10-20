
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import '../../../shared/responsive_utils.dart';
import '../../../theme/color_palette.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? overline;
  final String? subtitle;
  final IconData? leadingIcon;
  final String? tag;
  final Widget? trailing;
  final VoidCallback? onTrailingTap;
  final String? actionText;

  const SectionHeader({
    super.key,
    required this.title,
    this.overline,
    this.subtitle,
    this.leadingIcon,
    this.tag,
    this.trailing,
    this.onTrailingTap,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.scale(16, min: 12, max: 20),
        vertical: responsive.scale(8, min: 6, max: 12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (overline != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                overline!,
                style: TextStyle(
                  color: ColorPalette.primaryGreen,
                  fontSize: responsive.sp(10, min: 8.5, max: 11),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (leadingIcon != null) ...[
                      Icon(
                        leadingIcon,
                        size: responsive.iconSize(20, min: 16, max: 22),
                        color: ColorPalette.primaryGreen,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ColorPalette.fontWhite,
                          fontSize: responsive.sp(19, min: 15, max: 22),
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    if (tag != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: ColorPalette.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: ColorPalette.ghostBorder,
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          tag!,
                          style: TextStyle(
                            color: ColorPalette.primaryGreen,
                            fontSize: responsive.sp(10, min: 8.5, max: 11),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else if (actionText != null)
                DpadFocusable(
                  onSelect: () => onTrailingTap?.call(),

                  effects: [
                    DpadBorderEffect(
                      width: 2,
                      color: ColorPalette.primaryGreen,
                    ),
                    DpadTintEffect(color: ColorPalette.fontWhite),
                  ],
                  child: InkWell(
                    onTap: onTrailingTap,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          actionText!,
                          style: TextStyle(
                            color: ColorPalette.primaryGreen,
                            fontSize: responsive.sp(12, min: 10, max: 13),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: responsive.iconSize(16, min: 14, max: 18),
                          color: ColorPalette.primaryGreen,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitle!,
              style: TextStyle(
                color: ColorPalette.textMuted,
                fontSize: responsive.sp(11, min: 9.5, max: 12),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
