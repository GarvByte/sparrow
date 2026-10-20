import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sparrow/features/search/widgets/discover_poster_card.dart';
import 'package:sparrow/features/view_all/view_all_args.dart';
import 'package:sparrow/features/view_all/view_all_provider.dart';
import 'package:sparrow/navigation/dpad_navigation.dart';
import 'package:sparrow/shared/media_item.dart';
import 'package:sparrow/shared/navigation/movie_navigation.dart';
import 'package:sparrow/shared/navigation/tv_show_navigation.dart';
import 'package:sparrow/shared/responsive_utils.dart';
import 'package:sparrow/theme/color_palette.dart';

class ViewAllScreen extends ConsumerStatefulWidget {
  final ViewAllArgs args;

  const ViewAllScreen({super.key, required this.args});

  @override
  ConsumerState<ViewAllScreen> createState() => _ViewAllScreenState();
}

class _ViewAllScreenState extends ConsumerState<ViewAllScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onMediaTap(MediaItem item) {
    if (item.isTvShow || widget.args.isTv) {
      openTvShowDetails(context, item);
    } else {
      openMovieDetails(context, item);
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final topPadding = responsive.padding.top;
    final state = ref.watch(viewAllProvider(widget.args));
    final notifier = ref.read(viewAllProvider(widget.args).notifier);

    return Scaffold(
      backgroundColor: ColorPalette.backgroundBlack,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ColorPalette.backgroundBlack,
              ColorPalette.surface,
              ColorPalette.gradientEnd.withValues(alpha: 0.65),
            ],
          ),
        ),
        child: Column(
          children: [
            // Top App Bar
            _buildAppBar(context, topPadding, responsive),

            // Main Content Area
            Expanded(child: _buildBody(context, state, notifier, responsive)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    double topPadding,
    SparrowResponsive responsive,
  ) {
    return Container(
      padding: EdgeInsets.only(
        top: topPadding + 10,
        bottom: 12,
        left: responsive.scale(16, min: 12, max: 24),
        right: responsive.scale(16, min: 12, max: 24),
      ),
      decoration: BoxDecoration(
        color: ColorPalette.backgroundBlack.withValues(alpha: 0.85),
        border: const Border(
          bottom: BorderSide(color: ColorPalette.ghostBorder, width: 0.8),
        ),
      ),
      child: Row(
        children: [
          // Back Button
          IconButton(
            style: IconButton.styleFrom(
              padding: const EdgeInsets.only(left: 6),
              backgroundColor: const Color.fromARGB(45, 255, 255, 255),
            ),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(widget.args.isTv ? '/anime' : '/');
              }
            },
            icon: const Icon(
              Icons.arrow_back_ios,
              color: ColorPalette.fontWhite,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),

          // Title & Media Type Badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.args.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ColorPalette.fontWhite,
                    fontSize: responsive.sp(20, min: 17, max: 24),
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: ColorPalette.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.args.isTv
                          ? 'TV SHOWS COLLECTION'
                          : 'CINEMA COLLECTION',
                      style: const TextStyle(
                        color: ColorPalette.primaryGreen,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ViewAllState state,
    ViewAllNotifier notifier,
    SparrowResponsive responsive,
  ) {
    if (state.isLoadingInitial && state.items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: ColorPalette.primaryGreen,
        ),
      );
    }

    if (state.errorMessage != null && state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: ColorPalette.error,
                size: 48,
              ),
              const SizedBox(height: 14),
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: ColorPalette.textMuted),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorPalette.primaryGreen,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => notifier.retry(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.items.isEmpty) {
      return const Center(
        child: Text(
          'No titles available in this category.',
          style: TextStyle(color: ColorPalette.textMuted),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount = 2;
        if (width >= 1200) {
          crossAxisCount = 6;
        } else if (width >= 900) {
          crossAxisCount = 4;
        } else if (width >= 600) {
          crossAxisCount = 3;
        }

        final spacing = responsive.scale(12, min: 8, max: 16);
        final horizontalPadding = responsive.scale(16, min: 12, max: 24);

        return SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(
            left: horizontalPadding,
            right: horizontalPadding,
            top: 16,
            bottom: 120, // Clears floating bottom nav
          ),
          child: Column(
            children: [
              // Continuous Grid of Results (Page 1 + Page 2 + Paginated)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing + 8,
                  childAspectRatio: 2 / 3.75, // 2:3 poster + title & metadata
                ),
                itemCount: state.items.length,
                itemBuilder: (context, index) {
                  final item = state.items[index];
                  return DpadRegion(
                    memoryKey: 'viewall/${widget.args.categoryType}',
                    child: DpadFocusable(
                      onSelect: () => _onMediaTap(item),
                      effects: [
                        DpadBorderEffect(
                          width: 2,
                          color: ColorPalette.primaryGreen,
                        ),
                        DpadTintEffect(
                          color: ColorPalette.fontWhite,
                          opacity: 0.2,
                        ),
                      ],
                      child: DiscoverPosterCard(
                        item: item,
                        showRank: false,
                        onTap: () => _onMediaTap(item),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Bottom Load More Section
              if (state.errorMessage != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    state.errorMessage!,
                    style: const TextStyle(
                      color: ColorPalette.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],

              if (state.isLoadingMore)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: ColorPalette.primaryGreen,
                      ),
                    ),
                  ),
                )
              else if (state.hasMore)
                _buildLoadMoreArrowButton(notifier, responsive)
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: ColorPalette.textMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'You have reached the end',
                        style: TextStyle(
                          color: ColorPalette.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: ColorPalette.textMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Bottom-centered downward arrow button to load additional pages.
  Widget _buildLoadMoreArrowButton(
    ViewAllNotifier notifier,
    SparrowResponsive responsive,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => notifier.loadMore(),
              borderRadius: BorderRadius.circular(28),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: ColorPalette.surfaceContainerHighest,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ColorPalette.primaryGreen.withValues(alpha: 0.7),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ColorPalette.primaryGreen.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: ColorPalette.primaryGreen,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Load More',
              style: TextStyle(
                color: ColorPalette.primaryGreen,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
