import 'package:flutter/material.dart';
import 'package:sparrow/features/search/widgets/search_filter_sheet.dart';
import 'package:sparrow/navigation/dpad_navigation.dart';
import 'package:sparrow/shared/responsive_utils.dart';
import 'package:sparrow/theme/color_palette.dart';

class SearchBarDeck extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;

  const SearchBarDeck({
    super.key,
    required this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
  });

  @override
  State<SearchBarDeck> createState() => _SearchBarDeckState();
}

class _SearchBarDeckState extends State<SearchBarDeck> {
  late bool _hasText;
  late final FocusNode _internalFocusNode;
  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.isNotEmpty;
    _internalFocusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isTv = context.responsive.isTvOrDesktop;
    _focusNode.skipTraversal = !isTv;
  }

  @override
  void didUpdateWidget(covariant SearchBarDeck oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldFocusNode =
        oldWidget.focusNode ?? _internalFocusNode;
    final newFocusNode =
        widget.focusNode ?? _internalFocusNode;

    if (oldFocusNode != newFocusNode) {
      oldFocusNode.removeListener(_onFocusChange);
      newFocusNode.addListener(_onFocusChange);
    }
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
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
    _focusNode.removeListener(_onFocusChange);
    _internalFocusNode.dispose();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final isTv = responsive.isTvOrDesktop;
    final isFocused = isTv && _focusNode.hasFocus;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: ColorPalette.surfaceContainerHigh.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isFocused ? ColorPalette.primaryGreen : ColorPalette.ghostBorder,
          width: isFocused ? 2.0 : 0.8,
        ),
        boxShadow: [
          if (isFocused)
            BoxShadow(
              color: ColorPalette.primaryGreen.withValues(alpha: 0.35),
              blurRadius: 14,
              spreadRadius: 1.0,
            ),
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
              focusNode: _focusNode,
              controller: widget.controller,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              onTapOutside: (_) {
                _focusNode.unfocus(
                  disposition: UnfocusDisposition.previouslyFocusedChild,
                );
              },
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
            TvFocusable(
              borderRadius: BorderRadius.circular(14),
              onSelect: () {
                widget.controller.clear();
                widget.onClear?.call();
              },
              child: InkWell(
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
            ),
            const SizedBox(width: 8),
          ],

          // Filters / Tune Button
          TvFocusable(
            borderRadius: BorderRadius.circular(16),
            onSelect: () => SearchFilterSheet.show(context),
            child: InkWell(
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
          ),
        ],
      ),
    );
  }
}
