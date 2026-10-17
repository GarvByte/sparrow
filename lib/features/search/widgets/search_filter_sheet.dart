import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparrow/features/search/data/category_item.dart';
import 'package:sparrow/features/search/providers/search_filter_provider.dart';
import 'package:sparrow/features/search/providers/selected_category_provider.dart';
import 'package:sparrow/shared/responsive_utils.dart';
import 'package:sparrow/theme/color_palette.dart';

class SearchFilterSheet extends ConsumerWidget {
  const SearchFilterSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const SearchFilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsive = context.responsive;
    final currentFilter = ref.watch(searchFilterProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Container(
      decoration: BoxDecoration(
        color: ColorPalette.surfaceContainerLow.withValues(alpha: 0.96),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: ColorPalette.ghostBorder, width: 0.8),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ColorPalette.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter & Sort',
                style: TextStyle(
                  color: ColorPalette.fontWhite,
                  fontSize: responsive.sp(18, min: 16, max: 20),
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton(
                onPressed: () {
                  ref.read(searchFilterProvider.notifier).reset();
                  ref.read(selectedCategoryProvider.notifier).clear();
                  Navigator.pop(context);
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
            ],
          ),
          const SizedBox(height: 16),

          // Sort Options
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
                selectedColor: ColorPalette.primaryGreen.withValues(alpha: 0.2),
                backgroundColor: ColorPalette.surfaceContainer,
                labelStyle: TextStyle(
                  color: isSelected
                      ? ColorPalette.primaryGreen
                      : ColorPalette.textSecondary,
                  fontSize: responsive.sp(12, min: 10.5, max: 13),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                side: BorderSide(
                  color: isSelected
                      ? ColorPalette.primaryGreen
                      : ColorPalette.ghostBorder,
                ),
                onSelected: (selected) {
                  if (selected) {
                    ref.read(searchFilterProvider.notifier).setFilter(filter);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Category Filter
          Text(
            'CATEGORY / GENRE',
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
            children: [
              // All option
              ChoiceChip(
                label: const Text('All Categories'),
                selected: selectedCategory == null,
                selectedColor: ColorPalette.primaryGreen.withValues(alpha: 0.2),
                backgroundColor: ColorPalette.surfaceContainer,
                labelStyle: TextStyle(
                  color: selectedCategory == null
                      ? ColorPalette.primaryGreen
                      : ColorPalette.textSecondary,
                  fontSize: responsive.sp(12, min: 10.5, max: 13),
                  fontWeight: selectedCategory == null
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
                side: BorderSide(
                  color: selectedCategory == null
                      ? ColorPalette.primaryGreen
                      : ColorPalette.ghostBorder,
                ),
                onSelected: (selected) {
                  if (selected) {
                    ref.read(selectedCategoryProvider.notifier).clear();
                  }
                },
              ),
              ...CategoryItem.defaultCategories.map((cat) {
                final isSelected = selectedCategory?.id == cat.id;
                return ChoiceChip(
                  label: Text(cat.title),
                  selected: isSelected,
                  selectedColor: ColorPalette.primaryGreen.withValues(
                    alpha: 0.2,
                  ),
                  backgroundColor: ColorPalette.surfaceContainer,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? ColorPalette.primaryGreen
                        : ColorPalette.textSecondary,
                    fontSize: responsive.sp(12, min: 10.5, max: 13),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? ColorPalette.primaryGreen
                        : ColorPalette.ghostBorder,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      ref
                          .read(selectedCategoryProvider.notifier)
                          .setCategory(cat);
                    } else {
                      ref.read(selectedCategoryProvider.notifier).clear();
                    }
                  },
                );
              }),
            ],
          ),
          const SizedBox(height: 24),

          // Apply Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
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
    );
  }
}
