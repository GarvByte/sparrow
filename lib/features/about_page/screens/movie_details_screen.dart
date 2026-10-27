import 'package:cached_network_image/cached_network_image.dart';
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sparrow/features/about_page/data/movie_detail_info.dart';
import 'package:sparrow/features/about_page/providers/movie_details_provider.dart';
import 'package:sparrow/features/about_page/widgets/movie_audio_dropdown.dart';
import 'package:sparrow/features/about_page/widgets/movie_cast_section.dart';
import 'package:sparrow/features/about_page/widgets/movie_info_matrix.dart';
import 'package:sparrow/features/about_page/widgets/similar_movies_section.dart';
import 'package:sparrow/features/continue_watching/providers/continue_watching_provider.dart';
import 'package:sparrow/features/player/models/playback_context.dart';
import 'package:sparrow/features/player/providers/stream_resolution_provider.dart';
import 'package:sparrow/features/watchlist/data/watchlist_item.dart';
import 'package:sparrow/features/watchlist/providers/watchlist_provider.dart';
import 'package:sparrow/navigation/dpad_navigation.dart';
import 'package:sparrow/shared/error_image_placeholder.dart';
import 'package:sparrow/shared/media_item.dart';
import 'package:sparrow/shared/responsive_utils.dart';
import 'package:sparrow/theme/color_palette.dart';

/// Complete Movie Details ("About Movie") Page supporting Phone, Tablet, and TV.
///
/// Visual Architecture:
/// - Full-bleed cinematic hero backdrop with dark gradient overlays on all device formats.
/// - Adaptive app bar preserving the Sparrow visual identity (removing TV mockup extra tabs).
/// - Comprehensive metadata, rating badges, quality chips, and genre pills.
/// - Prominent emerald "Watch Now" action + "My List" and "Download" secondary controls.
/// - Mandatory Audio Selection dropdown with Hindi, Original Audio, Unverified.
/// - Expandable Synopsis narrative with "Read more" toggle.
/// - Additional Movie Information / Production Matrix bento grid.
/// - Horizontally scrollable Cast & Crew with circular portraits.
/// - Similar Movies carousel reusing existing [PortraitPosterCard].
class MovieDetailsScreen extends ConsumerStatefulWidget {
  final dynamic movieData;

  const MovieDetailsScreen({super.key, required this.movieData});

  @override
  ConsumerState<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends ConsumerState<MovieDetailsScreen> {
  bool _isSynopsisExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialItem = _resolveMediaItem();
      if (initialItem != null) {
        final playbackContext = PlaybackContext.movie(
          item: initialItem,
          imdbId: '',
        );
        ref
            .read(streamResolutionControllerProvider.notifier)
            .preloadServers(playbackContext);
      }
    });
  }

  void _openPlayer(BuildContext context, MediaItem item, MovieDetailInfo info) {
    final playbackContext = PlaybackContext.movie(
      item: item,
      imdbId: info.imdbId,
    );
    context.push('/player', extra: playbackContext);
  }

  void _toggleWatchlist(MovieDetailInfo info, MediaItem initialItem) {
    final item = WatchlistItem(
      id: initialItem.id,
      mediaType: 'movie',
      title: info.title.isNotEmpty ? info.title : initialItem.title,
      imageUrl: (info.posterUrl != null && info.posterUrl!.isNotEmpty)
          ? info.posterUrl!
          : initialItem.imageUrl,
      backdropUrl: info.backdropUrl ?? initialItem.backdropUrl,
      rating: info.rating ?? initialItem.rating,
      ratingCount: info.ratingCount ?? initialItem.ratingCount,
      genres: info.genres.isNotEmpty
          ? info.genres
          : initialItem.genres.map((e) => e.toString()).toList(),
      releaseDate: info.releaseDate ?? initialItem.releaseDate,
      overview: info.overview ?? initialItem.overview,
      isAdult: info.isAdult,
      addedAt: DateTime.now(),
    );
    ref.read(watchlistProvider.notifier).toggle(item);
  }

  MediaItem? _resolveMediaItem() {
    final data = widget.movieData;
    if (data == null) return null;
    if (data is MediaItem) return data;
    if (data is Map<String, dynamic>) {
      final rawId = data['id']?.toString() ?? '';
      if (rawId.isEmpty) return null;
      return MediaItem(
        id: rawId,
        title: (data['title'] ?? data['name'] ?? 'Untitled').toString(),
        imageUrl: data['imageUrl'] ?? '',
        genres: data['genres'] is List ? (data['genres'] as List) : [],
        rating: (data['rating'] as num?)?.toDouble(),
        ratingCount: data['ratingCount']?.toString(),
        overview: data['overview'] as String?,
        releaseDate: data['releaseDate'] as String?,
        backdropUrl: data['backdropUrl'] as String?,
        isAdult: (data['adult'] ?? data['isAdult']) as bool? ?? false,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final initialItem = _resolveMediaItem();

    if (initialItem == null || initialItem.id.trim().isEmpty) {
      return _buildInvalidMovieScreen(context);
    }

    // Watch detailed network data; initialItem provides instant zero-latency baseline
    final detailsAsync = ref.watch(movieDetailsProvider(initialItem));
    final info =
        detailsAsync.value ?? MovieDetailInfo.fromMediaItem(initialItem);

    final isBookmarked = ref.watch(
      isWatchlistedProvider((mediaType: 'movie', id: initialItem.id)),
    );

    final isTv = responsive.isTvOrDesktop;
    final isTablet = responsive.isTablet;

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
              ColorPalette.gradientEnd.withValues(alpha: 0.7),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Scrollable Content Viewport
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(
                // top: isTv ? responsive.headerHeight : 0,
                bottom: 80,
              ),
              child: isTv
                  ? _buildTvLayout(context, info, initialItem, isBookmarked)
                  : (isTablet
                        ? _buildTabletLayout(
                            context,
                            info,
                            initialItem,
                            isBookmarked,
                          )
                        : _buildMobileLayout(
                            context,
                            info,
                            initialItem,
                            isBookmarked,
                          )),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. MOBILE PHONE LAYOUT
  // ===========================================================================

  Widget _buildMobileLayout(
    BuildContext context,
    MovieDetailInfo info,
    MediaItem item,
    bool isBookmarked,
  ) {
    final responsive = context.responsive;
    final heroHeight = (responsive.width * 10 / 16).clamp(240.0, 360.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cinematic Hero Backdrop with Overlaid Floating Controls
        _buildMobileHero(context, info, item, heroHeight),

        // Primary Content Body
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: responsive.scale(16, min: 12, max: 20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 14),

              // Title Display
              Text(
                info.title,
                style: TextStyle(
                  color: ColorPalette.fontWhite,
                  fontSize: responsive.sp(26, min: 22, max: 32),
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),

              // Metadata & Formats Row
              _buildMetadataRow(context, info),
              const SizedBox(height: 10),

              // Genre Pills
              if (info.genres.isNotEmpty) ...[
                _buildGenrePills(context, info.genres),
                const SizedBox(height: 14),
              ],

              // Primary Actions: Watch Now + My List
              _buildPrimaryActionRow(context, info, item, isBookmarked),
              const SizedBox(height: 16),

              // Mandatory Audio Stream Dropdown
              MovieAudioDropdown(isTvOrDesktop: false),
              const SizedBox(height: 18),

              // Synopsis Section
              _buildSynopsisSection(context, info),
              const SizedBox(height: 20),

              // Additional Movie Information Grid
              MovieInfoMatrix(info: info, isTvOrDesktop: false),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Horizontally Scrollable Cast Section
        MovieCastSection(movieId: info.id, isTvOrDesktop: false),

        const SizedBox(height: 24),

        // Similar Movies Carousel
        SimilarMoviesSection(movieId: info.id, isTvOrDesktop: false),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildHeroArtwork({
    required String? posterUrl,
    required String? backdropUrl,
    required double height,
    required double width,
    Alignment alignment = Alignment.center,
  }) {
    final hasPoster = posterUrl != null && posterUrl.isNotEmpty;
    final hasBackdrop = backdropUrl != null && backdropUrl.isNotEmpty;
    final hasDistinctBackdrop =
        hasBackdrop && (!hasPoster || backdropUrl != posterUrl);

    return SizedBox(
      height: height,
      width: width,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Initial Poster Fallback Layer (displays immediately without flash/spinner)
          if (hasPoster)
            CachedNetworkImage(
              imageUrl: posterUrl,
              fit: BoxFit.cover,
              alignment: alignment,
              fadeInDuration: const Duration(milliseconds: 200),
              fadeOutDuration: const Duration(milliseconds: 200),
              errorWidget: (context, url, error) =>
                  const ErrorImagePlaceholder(),
            )
          else if (!hasBackdrop)
            const ErrorImagePlaceholder(),

          // 2. Full Backdrop Image Layer (smoothly crossfades in once loaded)
          if (hasDistinctBackdrop)
            CachedNetworkImage(
              imageUrl: backdropUrl,
              fit: BoxFit.cover,
              alignment: alignment,
              memCacheWidth: 1920,
              fadeInDuration: const Duration(milliseconds: 400),
              fadeOutDuration: const Duration(milliseconds: 200),
              placeholder: (context, url) => const SizedBox.shrink(),
              errorWidget: (context, url, error) => const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }

  /// Compact Mobile Hero Backdrop with dark gradient scrims.
  Widget _buildMobileHero(
    BuildContext context,
    MovieDetailInfo info,
    MediaItem item,
    double height,
  ) {
    final responsive = context.responsive;
    final topPadding = responsive.padding.top;

    return Stack(
      children: [
        // Backdrop Image with smooth poster-to-backdrop transition
        _buildHeroArtwork(
          posterUrl: info.posterUrl ?? item.imageUrl,
          backdropUrl: info.backdropUrl,
          height: height + topPadding,
          width: double.infinity,
          alignment: Alignment.center,
        ),

        // Obsidian Gradient Scrims
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.45, 0.85, 1.0],
                colors: [
                  ColorPalette.backgroundBlack.withValues(alpha: 0.65),
                  Colors.transparent,
                  ColorPalette.backgroundBlack.withValues(alpha: 0.80),
                  ColorPalette.backgroundBlack,
                ],
              ),
            ),
          ),
        ),

        // Telemetry Live Stream Indicator on Hero Bottom
        Positioned(
          bottom: 12,
          left: responsive.scale(16, min: 12, max: 20),
          child: info.tagline != null && info.tagline!.isNotEmpty
              ? Text(
                  info.tagline!.toUpperCase(),
                  style: const TextStyle(
                    color: ColorPalette.primaryGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                  ),
                )
              : const SizedBox.shrink(),
        ),
        Positioned(
          left: 24,
          top: 24,
          child: IconButton(
            style: IconButton.styleFrom(
              padding: EdgeInsets.only(left: 8),
              backgroundColor: const Color.fromARGB(62, 255, 255, 255),
            ),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              }
            },
            icon: Icon(Icons.arrow_back_ios),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 2. TV & DESKTOP LARGE SCREEN LAYOUT
  // ===========================================================================

  Widget _buildTvLayout(
    BuildContext context,
    MovieDetailInfo info,
    MediaItem item,
    bool isBookmarked,
  ) {
    final responsive = context.responsive;
    final horizontalPadding = responsive.scale(32.0, min: 24.0, max: 48.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TV Hero Backdrop Section
        Stack(
          children: [
            // Full-width Wide Cinematic Background with smooth poster-to-backdrop transition
            _buildHeroArtwork(
              posterUrl: info.posterUrl ?? item.imageUrl,
              backdropUrl: info.backdropUrl,
              height: 520,
              width: double.infinity,
              alignment: Alignment.center,
            ),

            // Horizontal & Vertical Scrim Gradients for Viewing Distance Legibility
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: const [0.0, 0.55, 1.0],
                    colors: [
                      ColorPalette.backgroundBlack.withValues(alpha: 0.95),
                      ColorPalette.backgroundBlack.withValues(alpha: 0.65),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.40, 0.85, 1.0],
                    colors: [
                      ColorPalette.backgroundBlack.withValues(alpha: 0.4),
                      Colors.transparent,
                      ColorPalette.backgroundBlack.withValues(alpha: 0.75),
                      ColorPalette.backgroundBlack,
                    ],
                  ),
                ),
              ),
            ),

            // TV Telemetry Ribbon & Header Metadata
            Positioned(
              left: horizontalPadding,
              top: 24,
              child: TvFocusable(
                borderRadius: BorderRadius.circular(24),
                onSelect: () {
                  if (context.canPop()) {
                    context.pop();
                  }
                },
                child: IconButton(
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.only(left: 8),
                    backgroundColor: const Color.fromARGB(62, 255, 255, 255),
                  ),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    }
                  },
                  icon: const Icon(Icons.arrow_back_ios),
                ),
              ),
            ),

            // TV Main Content Container overlaid on Backdrop
            Positioned(
              left: horizontalPadding,
              right: horizontalPadding,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Eyebrow Tagline
                  if (info.tagline != null && info.tagline!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        info.tagline!.toUpperCase(),
                        style: const TextStyle(
                          color: ColorPalette.primaryGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),

                  // TV Big Title
                  Text(
                    info.title,
                    style: const TextStyle(
                      color: ColorPalette.fontWhite,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.0,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // TV Metadata Bar
                  _buildTvMetadataBar(context, info),
                  const SizedBox(height: 14),

                  // Genre Pills
                  if (info.genres.isNotEmpty)
                    _buildGenrePills(context, info.genres),
                  const SizedBox(height: 20),

                  // TV Action Controls Row
                  Row(
                    children: [
                      // Large TV Watch Now Button
                      DpadFocusable(
                        onSelect: () => _openPlayer(context, item, info),
                        effects: [
                          DpadScaleEffect(scale: 1.05),
                          DpadTintEffect(
                            borderRadius: BorderRadius.circular(50),
                            color: ColorPalette.fontWhite,
                            opacity: 0.2,
                          ),
                        ],
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _openPlayer(context, item, info);
                          },
                          icon: const Icon(
                            Icons.play_arrow_rounded,
                            size: 28,
                            color: Colors.black,
                          ),
                          label: Text(
                            ref.watch(hasPlaybackProgressProvider('movie_${item.id}'))
                                ? 'Resume'
                                : 'Watch Now',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorPalette.primaryGreen,
                            elevation: 8,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // TV Bookmark Button
                      _buildTvGhostIconButton(
                        icon: isBookmarked
                            ? Icons.bookmark_added_rounded
                            : Icons.bookmark_add_outlined,
                        isSelected: isBookmarked,
                        onTap: () => _toggleWatchlist(info, item),
                      ),
                      const SizedBox(width: 16),

                      // TV Audio Dropdown
                      MovieAudioDropdown(isTvOrDesktop: true),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),

        // Two-Column TV Dossier Section: Left Key Art + Synopsis, Right Production Matrix
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Theatrical Poster + Rich Synopsis
              Expanded(
                flex: 6,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vertical 2:3 Key Art
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 180,
                        height: 270,
                        decoration: BoxDecoration(
                          color: ColorPalette.surfaceContainerHigh,
                          border: Border.all(
                            color: ColorPalette.ghostBorderLight,
                            width: 1,
                          ),
                        ),
                        child:
                            (info.posterUrl != null &&
                                info.posterUrl!.isNotEmpty)
                            ? CachedNetworkImage(
                                imageUrl: info.posterUrl!,
                                fit: BoxFit.cover,
                                fadeInDuration: const Duration(
                                  milliseconds: 200,
                                ),
                                fadeOutDuration: const Duration(
                                  milliseconds: 200,
                                ),
                                errorWidget: (context, url, error) =>
                                    const ErrorImagePlaceholder(),
                              )
                            : const ErrorImagePlaceholder(),
                      ),
                    ),
                    const SizedBox(width: 24),

                    // Synopsis & Telemetry Chips
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 3,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: ColorPalette.primaryGreen,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'SYNOPSIS',
                                style: TextStyle(
                                  color: ColorPalette.fontWhite,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            info.overview?.isNotEmpty == true
                                ? info.overview!
                                : 'No synopsis available for this title.',
                            style: const TextStyle(
                              color: ColorPalette.fontWhite,
                              fontSize: 15,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 18),

                          // TV Feature Telemetry Metric Badges
                          Row(
                            children: [
                              _buildTvTelemetryBadge(
                                'ASPECT RATIO',
                                '1.43 : 1',
                                'IMAX NATIVE',
                              ),
                              const SizedBox(width: 12),
                              _buildTvTelemetryBadge(
                                'DYNAMIC RANGE',
                                '1,000 NITS',
                                'DOLBY VISION',
                              ),
                              const SizedBox(width: 12),
                              _buildTvTelemetryBadge(
                                'TIER',
                                'ULTRA 4K',
                                'ZERO LOSS',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 32),

              // Right Column: Production Matrix Bento Card
              Expanded(
                flex: 5,
                child: MovieInfoMatrix(info: info, isTvOrDesktop: true),
              ),
            ],
          ),
        ),

        const SizedBox(height: 36),

        // Section 1: Cast & Crew
        DpadRegion(
          child: MovieCastSection(movieId: info.id, isTvOrDesktop: true),
        ),

        const SizedBox(height: 36),

        // Section 2: Similar Movies
        SimilarMoviesSection(movieId: info.id, isTvOrDesktop: true),

        const SizedBox(height: 40),
      ],
    );
  }

  // ===========================================================================
  // 3. TABLET LAYOUT
  // ===========================================================================

  Widget _buildTabletLayout(
    BuildContext context,
    MovieDetailInfo info,
    MediaItem item,
    bool isBookmarked,
  ) {
    final responsive = context.responsive;
    final paddingH = responsive.scale(24.0, min: 20.0, max: 32.0);
    final heroHeight = (responsive.width * 9 / 16).clamp(300.0, 420.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMobileHero(context, info, item, heroHeight),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: paddingH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                info.title,
                style: TextStyle(
                  color: ColorPalette.fontWhite,
                  fontSize: responsive.sp(32, min: 26, max: 38),
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              _buildMetadataRow(context, info),
              const SizedBox(height: 12),
              if (info.genres.isNotEmpty) ...[
                _buildGenrePills(context, info.genres),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildWatchNowButton(context, item, info),
                  ),
                  const SizedBox(width: 12),
                  _buildGhostButton(
                    icon: isBookmarked
                        ? Icons.bookmark_added_rounded
                        : Icons.add_rounded,
                    label: isBookmarked ? 'In My List' : 'My List',
                    isBookmarked: isBookmarked,
                    onTap: () => _toggleWatchlist(info, item),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: MovieAudioDropdown(isTvOrDesktop: false),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: _buildSynopsisSection(context, info),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 6,
                    child: MovieInfoMatrix(info: info, isTvOrDesktop: true),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        MovieCastSection(movieId: info.id, isTvOrDesktop: false),
        const SizedBox(height: 28),
        SimilarMoviesSection(movieId: info.id, isTvOrDesktop: false),
        const SizedBox(height: 24),
      ],
    );
  }

  // ===========================================================================
  // SHARED SUB-WIDGET BUILDERS
  // ===========================================================================

  Widget _buildMetadataRow(BuildContext context, MovieDetailInfo info) {
    final responsive = context.responsive;
    final ratingVal = info.rating != null
        ? info.rating!.toStringAsFixed(1)
        : '8.0';
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [
        Text(
          info.releaseYear,
          style: TextStyle(
            color: ColorPalette.fontWhite,
            fontSize: responsive.sp(13, min: 11, max: 14),
            fontWeight: FontWeight.w600,
          ),
        ),
        _buildDot(),
        if (info.runtimeFormatted.isNotEmpty) ...[
          Text(
            info.runtimeFormatted,
            style: TextStyle(
              color: ColorPalette.textMuted,
              fontSize: responsive.sp(13, min: 11, max: 14),
            ),
          ),
          _buildDot(),
        ],
        _buildBadge(info.isAdult ? 'Adult 18+' : 'Not Adult'),

        _buildDot(),
        // IMDb Rating Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: ColorPalette.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star_rounded,
                size: 15,
                color: Color(0xFFFACC15),
              ),
              const SizedBox(width: 3),
              Text(
                ratingVal,
                style: TextStyle(
                  color: ColorPalette.fontWhite,
                  fontSize: responsive.sp(12, min: 10.5, max: 13),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 3),
              const Text(
                'IMDb',
                style: TextStyle(
                  color: ColorPalette.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        _buildDot(),
        _buildBadge('IMAX 4K', isPrimary: true),
        _buildDot(),
        _buildBadge('Dolby Atmos'),
      ],
    );
  }

  Widget _buildTvMetadataBar(BuildContext context, MovieDetailInfo info) {
    final ratingVal = info.rating != null
        ? info.rating!.toStringAsFixed(1)
        : '8.0';

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Text(
          info.releaseYear,
          style: const TextStyle(
            color: ColorPalette.fontWhite,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        _buildTvDot(),
        if (info.runtimeFormatted.isNotEmpty) ...[
          Text(
            info.runtimeFormatted,
            style: const TextStyle(color: ColorPalette.textMuted, fontSize: 16),
          ),
          _buildTvDot(),
        ],
        _buildBadge(info.isAdult ? "Adult 18+" : 'Not Adult'),
        _buildTvDot(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFF5C518).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: const Color(0xFFF5C518).withValues(alpha: 0.4),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star_rounded,
                size: 18,
                color: Color(0xFFF5C518),
              ),
              const SizedBox(width: 4),
              Text(
                ratingVal,
                style: const TextStyle(
                  color: Color(0xFFF5C518),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (info.ratingCount != null) ...[
                const SizedBox(width: 4),
                Text(
                  '(${info.ratingCount} votes)',
                  style: const TextStyle(
                    color: ColorPalette.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
        _buildBadge('IMAX 4K', isPrimary: true),
        _buildBadge('DOLBY VISION'),
        _buildBadge('DOLBY ATMOS'),
      ],
    );
  }

  Widget _buildGenrePills(BuildContext context, List<String> genres) {
    final responsive = context.responsive;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: genres.map((genre) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: EdgeInsets.symmetric(
              horizontal: responsive.scale(12, min: 10, max: 14),
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: ColorPalette.surfaceContainer,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: ColorPalette.ghostBorder, width: 0.8),
            ),
            child: Text(
              genre,
              style: TextStyle(
                color: ColorPalette.fontWhite,
                fontSize: responsive.sp(11.5, min: 10, max: 13),
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPrimaryActionRow(
    BuildContext context,
    MovieDetailInfo info,
    MediaItem item,
    bool isBookmarked,
  ) {
    return Row(
      children: [
        // Watch Now Action
        Expanded(child: _buildWatchNowButton(context, item, info)),
        const SizedBox(width: 10),

        // My List
        _buildGhostButton(
          icon: isBookmarked ? Icons.bookmark_added_rounded : Icons.add_rounded,
          label: isBookmarked ? 'In My List' : 'My List',
          isBookmarked: isBookmarked,
          onTap: () => _toggleWatchlist(info, item),
        ),
      ],
    );
  }

  Widget _buildWatchNowButton(
    BuildContext context,
    MediaItem item,
    MovieDetailInfo info,
  ) {
    final hasProgress =
        ref.watch(hasPlaybackProgressProvider('movie_${item.id}'));
    return ElevatedButton.icon(
      onPressed: () => _openPlayer(context, item, info),
      icon: const Icon(Icons.play_arrow_rounded, size: 24, color: Colors.black),
      label: Text(
        hasProgress ? 'Resume' : 'Watch Now',
        style: const TextStyle(
          color: Colors.black,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorPalette.primaryGreen,
        elevation: 6,
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildGhostButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isBookmarked = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isBookmarked
              ? ColorPalette.primaryGreen.withValues(alpha: 0.15)
              : ColorPalette.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isBookmarked
                ? ColorPalette.primaryGreen.withValues(alpha: 0.6)
                : ColorPalette.ghostBorder,
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isBookmarked
                  ? ColorPalette.primaryGreen
                  : ColorPalette.fontWhite,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isBookmarked
                    ? ColorPalette.primaryGreen
                    : ColorPalette.fontWhite,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTvGhostIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return TvFocusable(
      borderRadius: BorderRadius.circular(30),
      onSelect: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: isSelected
                ? ColorPalette.primaryGreen.withValues(alpha: 0.2)
                : ColorPalette.surfaceContainer.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected
                  ? ColorPalette.primaryGreen
                  : ColorPalette.ghostBorderLight,
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: 24,
            color: isSelected
                ? ColorPalette.primaryGreen
                : ColorPalette.fontWhite,
          ),
        ),
      ),
    );
  }

  Widget _buildSynopsisSection(BuildContext context, MovieDetailInfo info) {
    final responsive = context.responsive;
    final overviewText = info.overview?.isNotEmpty == true
        ? info.overview!
        : 'Follow the epic cinematic journey in this acclaimed motion picture.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 18,
              decoration: BoxDecoration(
                color: ColorPalette.primaryGreen,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Synopsis',
              style: TextStyle(
                color: ColorPalette.fontWhite,
                fontSize: responsive.sp(18, min: 15, max: 22),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          overviewText,
          maxLines: _isSynopsisExpanded ? null : 3,
          overflow: _isSynopsisExpanded
              ? TextOverflow.visible
              : TextOverflow.ellipsis,
          style: TextStyle(
            color: ColorPalette.fontWhite.withValues(alpha: 0.92),
            fontSize: responsive.sp(13.5, min: 12, max: 15.5),
            height: 1.55,
          ),
        ),
        if (overviewText.length > 140) ...[
          const SizedBox(height: 6),
          InkWell(
            onTap: () {
              setState(() {
                _isSynopsisExpanded = !_isSynopsisExpanded;
              });
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isSynopsisExpanded ? 'Show less' : 'Read more',
                  style: const TextStyle(
                    color: ColorPalette.primaryGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Icon(
                  _isSynopsisExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 18,
                  color: ColorPalette.primaryGreen,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBadge(String label, {bool isPrimary = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isPrimary
            ? ColorPalette.primaryGreen.withValues(alpha: 0.15)
            : ColorPalette.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(4),
        border: isPrimary
            ? Border.all(
                color: ColorPalette.primaryGreen.withValues(alpha: 0.4),
                width: 0.8,
              )
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isPrimary ? ColorPalette.primaryGreen : ColorPalette.fontWhite,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDot() {
    return Container(
      width: 3.5,
      height: 3.5,
      decoration: const BoxDecoration(
        color: ColorPalette.textMuted,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildTvDot() {
    return Container(
      width: 5,
      height: 5,
      decoration: const BoxDecoration(
        color: ColorPalette.textMuted,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildTvTelemetryBadge(String label, String value, String sub) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: ColorPalette.surfaceContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ColorPalette.ghostBorder, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: ColorPalette.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: ColorPalette.fontWhite,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            sub,
            style: const TextStyle(
              color: ColorPalette.primaryGreen,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvalidMovieScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.backgroundBlack,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.movie_filter_outlined,
                size: 56,
                color: ColorPalette.primaryGreen,
              ),
              const SizedBox(height: 16),
              const Text(
                'Movie Not Found',
                style: TextStyle(
                  color: ColorPalette.fontWhite,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Invalid or missing movie identifier.',
                textAlign: TextAlign.center,
                style: TextStyle(color: ColorPalette.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorPalette.primaryGreen,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Go Back',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
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
