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
import 'package:sparrow/shared/scroll_aware_header.dart';
import 'package:sparrow/theme/color_palette.dart';

class ViewAllScreen extends ConsumerStatefulWidget {
  final ViewAllArgs args;

  const ViewAllScreen({super.key, required this.args});

  @override
  ConsumerState<ViewAllScreen> createState() => _ViewAllScreenState();
}

class _ViewAllScreenState extends ConsumerState<ViewAllScreen> {
  final ScrollController _scrollController = ScrollController();
  final ScrollAwareHeaderController _headerController =
      ScrollAwareHeaderController();

  @override
  void dispose() {
    _scrollController.dispose();
    _headerController.dispose();
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
        child: Stack(
          children: [
            // Main Content Area
            NotificationListener<ScrollNotification>(
              onNotification: _headerController.handleScrollNotification,
              child: _buildBody(
                context,
                state,
                notifier,
                responsive,
                topOffset: topPadding + 66,
              ),
            ),

            // Top App Bar with Scroll Awareness
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ScrollAwareHeader(
                controller: _headerController,
                child: _buildAppBar(context, topPadding, responsive),
              ),
            ),
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
          TvFocusable(
            onSelect: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(widget.args.isTv ? '/anime' : '/');
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: IconButton(
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
    SparrowResponsive responsive, {
    double topOffset = 0,
  }) {
    if (state.isLoadingInitial && state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.only(top: topOffset),
          child: const CircularProgressIndicator(
            strokeWidth: 2.5,
            color: ColorPalette.primaryGreen,
          ),
        ),
      );
    }

    if (state.errorMessage != null && state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.only(
            top: topOffset,
            left: 24.0,
            right: 24.0,
            bottom: 24.0,
          ),
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
              TvFocusable(
                onSelect: () => notifier.retry(),
                borderRadius: BorderRadius.circular(12),
                child: ElevatedButton.icon(
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
              ),
            ],
          ),
        ),
      );
    }

    if (state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.only(top: topOffset),
          child: const Text(
            'No titles available in this category.',
            style: TextStyle(color: ColorPalette.textMuted),
          ),
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
            top: topOffset + 12,
            bottom: 120, // Clears floating bottom nav
          ),
          child: Column(
            children: [
              // Continuous Grid of Results wrapped in DpadRegion
              DpadRegion(
                memoryKey: 'viewall/${widget.args.categoryType}',
                leftEdge: DpadEdgeBehavior.leave,
                child: GridView.builder(
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
                    return FocusablePosterCard(
                      onSelected: () => _onMediaTap(item),
                      child: DiscoverPosterCard(
                        item: item,
                        showRank: false,
                        onTap: () => _onMediaTap(item),
                      ),
                    );
                  },
                ),
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
                ),

              if (state.hasMore && !state.isLoadingMore)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: TvFocusable(
                    onSelect: () => notifier.loadMore(),
                    borderRadius: BorderRadius.circular(24),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ColorPalette.primaryGreen,
                        side: const BorderSide(
                          color: ColorPalette.primaryGreen,
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () => notifier.loadMore(),
                      child: const Text('Load More Titles'),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
