import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparrow/features/search/data/category_item.dart';
import 'package:sparrow/features/search/providers/searchQueryProvider.dart';
import 'package:sparrow/features/search/providers/search_filter_provider.dart';
import 'package:sparrow/features/search/providers/search_results_provider.dart';
import 'package:sparrow/features/search/providers/selected_category_provider.dart';
import 'package:sparrow/shared/responsive_utils.dart';
import 'package:sparrow/theme/color_palette.dart';

class SearchFilterSheet extends ConsumerWidget {
  const SearchFilterSheet({super.key});

  /// Opens the filter interface centered in the screen as a dialog.
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (context) => const SearchFilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsive = context.responsive;
    final currentMediaType = ref.watch(searchMediaTypeProvider);
    final currentFilter = ref.watch(searchFilterProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: responsive.scale(16, min: 14, max: 24),
        vertical: 24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: (responsive.isTvOrDesktop || responsive.isTablet)
                ? 440
                : 380,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: ColorPalette.surfaceContainerLow.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: ColorPalette.ghostBorder, width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pinned Dialog Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: ColorPalette.primaryGreen.withValues(
                                alpha: 0.15,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.tune_rounded,
                              size: 18,
                              color: ColorPalette.primaryGreen,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Search Filters',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: ColorPalette.fontWhite,
                                fontSize: responsive.sp(17, min: 15, max: 20),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () {
                            ref.read(searchMediaTypeProvider.notifier).reset();
                            ref.read(searchFilterProvider.notifier).reset();
                            ref.read(selectedCategoryProvider.notifier).clear();
                            final query = ref.read(searchQueryProvider);
                            if (query.trim().isNotEmpty) {
                              ref
                                  .read(searchResultsNotifier.notifier)
                                  .search(
                                    query: query,
                                    mediaType: SearchMediaType.movies,
                                  );
                            }
                          },
                          child: Text(
                            'Reset',
                            style: TextStyle(
                              color: ColorPalette.primaryGreen,
                              fontSize: responsive.sp(13, min: 11, max: 14),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: ColorPalette.surfaceContainerHighest
                                  .withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: ColorPalette.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Scrollable Content
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. MEDIA TYPE Selector (Movies vs TV Shows)
                        Text(
                          'MEDIA TYPE',
                          style: TextStyle(
                            color: ColorPalette.textMuted,
                            fontSize: responsive.sp(11, min: 10, max: 12),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: SearchMediaType.values.map((type) {
                            final isSelected = type == currentMediaType;
                            final icon = type == SearchMediaType.movies
                                ? Icons.movie_outlined
                                : Icons.tv_rounded;

                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: type == SearchMediaType.movies
                                      ? 8.0
                                      : 0.0,
                                  left: type == SearchMediaType.tvShows
                                      ? 8.0
                                      : 0.0,
                                ),
                                child: InkWell(
                                  onTap: () {
                                    ref
                                        .read(searchMediaTypeProvider.notifier)
                                        .setType(type);
                                  },
                                  borderRadius: BorderRadius.circular(14),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? ColorPalette.primaryGreen
                                                .withValues(alpha: 0.18)
                                          : ColorPalette.surfaceContainer,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSelected
                                            ? ColorPalette.primaryGreen
                                            : ColorPalette.ghostBorder,
                                        width: isSelected ? 1.5 : 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          icon,
                                          size: 18,
                                          color: isSelected
                                              ? ColorPalette.primaryGreen
                                              : ColorPalette.textSecondary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          type.label,
                                          style: TextStyle(
                                            color: isSelected
                                                ? ColorPalette.primaryGreen
                                                : ColorPalette.textSecondary,
                                            fontSize: responsive.sp(
                                              13,
                                              min: 11.5,
                                              max: 14,
                                            ),
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 18),

                        // 2. SORT BY Options
                        Text(
                          'SORT BY',
                          style: TextStyle(
                            color: ColorPalette.textMuted,
                            fontSize: responsive.sp(11, min: 10, max: 12),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: SearchSortFilter.values.map((filter) {
                            final isSelected = filter == currentFilter;
                            return ChoiceChip(
                              label: Text(filter.label),
                              selected: isSelected,
                              selectedColor: ColorPalette.primaryGreen
                                  .withValues(alpha: 0.2),
                              backgroundColor: ColorPalette.surfaceContainer,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? ColorPalette.primaryGreen
                                    : ColorPalette.textSecondary,
                                fontSize: responsive.sp(12, min: 10.5, max: 13),
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                              side: BorderSide(
                                color: isSelected
                                    ? ColorPalette.primaryGreen
                                    : ColorPalette.ghostBorder,
                                width: isSelected ? 1.2 : 0.8,
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  ref
                                      .read(searchFilterProvider.notifier)
                                      .setFilter(filter);
                                }
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 18),

                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Pinned Apply Button at Bottom
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      final query = ref.read(searchQueryProvider);
                      if (query.trim().isNotEmpty) {
                        ref
                            .read(searchResultsNotifier.notifier)
                            .search(query: query);
                      }
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorPalette.primaryGreen,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Apply Filters',
                      style: TextStyle(
                        fontSize: responsive.sp(14, min: 12, max: 16),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
