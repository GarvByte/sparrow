import 'package:flutter/material.dart';
import 'package:sparrow/features/search/widgets/search_filter_sheet.dart';
import 'package:sparrow/shared/responsive_utils.dart';
import 'package:sparrow/theme/color_palette.dart';

class SearchBarDeck extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;

  const SearchBarDeck({
    super.key,
    required this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
  });

  @override
  State<SearchBarDeck> createState() => _SearchBarDeckState();
}

class _SearchBarDeckState extends State<SearchBarDeck> {
  late bool _hasText;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.isNotEmpty;
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: ColorPalette.surfaceContainerHigh.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ColorPalette.ghostBorder, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Search Icon
          const Icon(
            Icons.search_rounded,
            size: 22,
            color: ColorPalette.primaryGreen,
          ),
          const SizedBox(width: 10),

          // Search Text Input
          Expanded(
            child: TextField(
              controller: widget.controller,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              textInputAction: TextInputAction.search,
              style: TextStyle(
                color: ColorPalette.fontWhite,
                fontSize: responsive.sp(14, min: 12.5, max: 15.5),
                fontWeight: FontWeight.w400,
              ),
              cursorColor: ColorPalette.primaryGreen,
              decoration: InputDecoration(
                hintText: 'Search movies, actors, genres...',
                hintStyle: TextStyle(
                  color: ColorPalette.textSecondary.withValues(alpha: 0.65),
                  fontSize: responsive.sp(13.5, min: 12, max: 15),
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),

          // Clear Button (only when text is not empty)
          if (_hasText) ...[
            InkWell(
              onTap: () {
                widget.controller.clear();
                widget.onClear?.call();
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: ColorPalette.surfaceContainerHighest.withValues(
                    alpha: 0.8,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 15,
                  color: ColorPalette.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],

          // Voice Search (Mic) Button
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Voice search is not supported on this device.',
                  ),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(
                Icons.mic_none_rounded,
                size: 20,
                color: ColorPalette.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Filters / Tune Button
          InkWell(
            onTap: () => SearchFilterSheet.show(context),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: ColorPalette.surfaceContainer,
                shape: BoxShape.circle,
                border: Border.all(color: ColorPalette.ghostBorder, width: 0.5),
              ),
              child: const Icon(
                Icons.tune_rounded,
                size: 17,
                color: ColorPalette.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
