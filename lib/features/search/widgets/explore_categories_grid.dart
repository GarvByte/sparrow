import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparrow/features/search/data/category_item.dart';
import 'package:sparrow/features/search/providers/selected_category_provider.dart';
import 'package:sparrow/shared/responsive_utils.dart';
import 'package:sparrow/theme/color_palette.dart';

class ExploreCategoriesGrid extends ConsumerWidget {
  final ValueChanged<CategoryItem>? onCategoryTap;

  const ExploreCategoriesGrid({super.key, this.onCategoryTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsive = context.responsive;
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final categories = CategoryItem.defaultCategories;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.scale(16, min: 12, max: 20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Container(
                width: 5,
                height: 16,
                decoration: BoxDecoration(
                  color: ColorPalette.primaryGreen,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: ColorPalette.primaryGreen.withValues(alpha: 0.6),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Explore Categories',
                style: TextStyle(
                  color: ColorPalette.fontWhite,
                  fontSize: responsive.sp(18, min: 15, max: 21),
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Responsive Adaptive Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              int crossAxisCount = 2;
              if (width >= 1100) {
                crossAxisCount = 6;
              } else if (width >= 800) {
                crossAxisCount = 4;
              } else if (width >= 560) {
                crossAxisCount = 3;
              }

              final spacing = responsive.scale(10, min: 8, max: 14);
              final itemHeight = responsive.scale(112, min: 100, max: 128);

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  mainAxisExtent: itemHeight,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = selectedCategory?.id == cat.id;

                  return _CategoryCard(
                    category: cat,
                    isSelected: isSelected,
                    onTap: () {
                      if (isSelected) {
                        ref.read(selectedCategoryProvider.notifier).clear();
                      } else {
                        ref
                            .read(selectedCategoryProvider.notifier)
                            .setCategory(cat);
                        onCategoryTap?.call(cat);
                      }
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryItem category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(responsive.radius(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: ColorPalette.primaryGreen.withValues(alpha: 0.15),
        highlightColor: ColorPalette.primaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(responsive.radius(16)),
        child: Container(
          decoration: BoxDecoration(
            color: ColorPalette.surfaceContainer,
            borderRadius: BorderRadius.circular(responsive.radius(16)),
            border: Border.all(
              color: isSelected
                  ? ColorPalette.primaryGreen
                  : ColorPalette.ghostBorder,
              width: isSelected ? 1.5 : 0.8,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: ColorPalette.primaryGreen.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Artwork
              Opacity(
                opacity: 0.38,
                child: CachedNetworkImage(
                  imageUrl: category.imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) =>
                      Container(color: ColorPalette.surfaceContainerHigh),
                ),
              ),

              // Gradient Overlay (dark obsidian to atmospheric accent tint)
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [
                      ColorPalette.backgroundBlack.withValues(alpha: 0.92),
                      ColorPalette.backgroundBlack.withValues(alpha: 0.65),
                      category.accentColor.withValues(alpha: 0.22),
                    ],
                  ),
                ),
              ),

              // Content Layout
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top-Left Frosted Icon Container
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: ColorPalette.surfaceContainerHighest.withValues(
                          alpha: 0.75,
                        ),
                        borderRadius: BorderRadius.circular(
                          responsive.radius(8),
                        ),
                        border: Border.all(
                          color: ColorPalette.ghostBorder,
                          width: 0.5,
                        ),
                      ),
                      child: Icon(
                        category.icon,
                        size: 17,
                        color: category.accentColor,
                      ),
                    ),

                    // Bottom: Title & Subtitle
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          category.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ColorPalette.fontWhite,
                            fontSize: responsive.sp(14, min: 12, max: 16),
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          category.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ColorPalette.textSecondary,
                            fontSize: responsive.sp(10, min: 9, max: 11.5),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned.fill(
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    onTap: onTap,
                    splashColor: ColorPalette.fontWhite.withValues(alpha: 0.35),
                    highlightColor: ColorPalette.primaryGreen.withValues(
                      alpha: 0.12,
                    ),
                    borderRadius: BorderRadius.circular(responsive.radius(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
