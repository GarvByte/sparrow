import 'package:cached_network_image/cached_network_image.dart';
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sparrow/features/about_page/widgets/movie_audio_dropdown.dart';
import 'package:sparrow/features/tv_show_details/data/tv_season_model.dart';
import 'package:sparrow/features/tv_show_details/data/tv_show_detail_info.dart';
import 'package:sparrow/features/tv_show_details/providers/tv_show_details_provider.dart';
import 'package:sparrow/features/tv_show_details/widgets/similar_tv_shows_section.dart';
import 'package:sparrow/features/tv_show_details/widgets/tv_cast_section.dart';
import 'package:sparrow/features/tv_show_details/widgets/tv_episode_carousel.dart';
import 'package:sparrow/features/tv_show_details/widgets/tv_episode_list.dart';
import 'package:sparrow/features/tv_show_details/widgets/tv_show_info_matrix.dart';
import 'package:sparrow/features/watchlist/data/watchlist_item.dart';
import 'package:sparrow/features/watchlist/providers/watchlist_provider.dart';
import 'package:sparrow/navigation/dpad_navigation.dart';
import 'package:sparrow/shared/error_image_placeholder.dart';
import 'package:sparrow/shared/media_item.dart';
import 'package:sparrow/shared/responsive_utils.dart';
import 'package:sparrow/theme/color_palette.dart';

/// Complete TV Show Details ("About TV Show") Screen supporting Phone, Tablet, and TV.
///
/// Visual Architecture:
/// - Full-bleed cinematic hero backdrop with obsidian gradient scrims.
/// - Back navigation button without extra global application header tabs.
/// - Metadata row with air years, seasons, adult indicator, IMDb rating, and quality tags.
/// - Prominent emerald "Watch Now" action + "My List" and "Download" secondary controls.
/// - Mandatory Audio Selection dropdown reusing Sparrow's established [MovieAudioDropdown].
/// - Expandable synopsis narrative with "Read more" toggle.
/// - Dynamic Season selection and Episode layout:
///   * Vertically scrolling episode cards on Mobile and Tablet.
///   * Horizontally scrolling 16:9 episode carousel on TV / Large Landscape.
/// - "About [Show]" production telemetry matrix (2-col mobile, 4-col TV Bento).
/// - Horizontally scrollable Cast & Crew portraits.
/// - Curated Similar TV Shows carousel reusing [PortraitPosterCard].
class TvShowDetailsScreen extends ConsumerStatefulWidget {
  final dynamic tvData;

  const TvShowDetailsScreen({super.key, required this.tvData});

  @override
  ConsumerState<TvShowDetailsScreen> createState() =>
      _TvShowDetailsScreenState();
}

class _TvShowDetailsScreenState extends ConsumerState<TvShowDetailsScreen> {
  bool _isSynopsisExpanded = false;

  void _toggleWatchlist(TvShowDetailInfo info, MediaItem initialItem) {
    final item = WatchlistItem(
      id: initialItem.id,
      mediaType: 'tv',
      title: info.name.isNotEmpty ? info.name : initialItem.title,
      imageUrl: (info.posterUrl != null && info.posterUrl!.isNotEmpty)
          ? info.posterUrl!
          : initialItem.imageUrl,
      backdropUrl: info.backdropUrl ?? initialItem.backdropUrl,
      rating: info.rating ?? initialItem.rating,
      ratingCount: info.ratingCount ?? initialItem.ratingCount,
      genres: info.genres.isNotEmpty
          ? info.genres
          : initialItem.genres.map((e) => e.toString()).toList(),
      releaseDate: info.firstAirDate ?? initialItem.releaseDate,
      overview: info.overview ?? initialItem.overview,
      isAdult: info.isAdult,
      addedAt: DateTime.now(),
    );
    ref.read(watchlistProvider.notifier).toggle(item);
  }

  MediaItem? _resolveMediaItem() {
    final data = widget.tvData;
    if (data == null) return null;
    if (data is MediaItem) return data;
    if (data is Map<String, dynamic>) {
      final rawId = data['id']?.toString() ?? '';
      if (rawId.isEmpty) return null;
      return MediaItem(
        id: rawId,
        title: (data['name'] ?? data['title'] ?? 'Untitled').toString(),
        imageUrl: data['imageUrl'] ?? '',
        genres: data['genres'] is List ? (data['genres'] as List) : [],
        rating: (data['rating'] as num?)?.toDouble(),
        ratingCount: data['ratingCount']?.toString(),
        overview: data['overview'] as String?,
        releaseDate: (data['firstAirDate'] ?? data['releaseDate']) as String?,
        backdropUrl: data['backdropUrl'] as String?,
        isAdult: (data['adult'] ?? data['isAdult']) as bool? ?? false,
        mediaType: 'tv',
      );
    }
    return null;
  }

  void _handleEpisodePlayback(TvEpisodeInfo episode, String seriesId) {
    //debugPrintt(
    // 'Episode playback selected: Series $seriesId, Season ${episode.seasonNumber}, Episode ${episode.episodeNumber} (${episode.name})',
    // );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ColorPalette.surfaceContainerHighest,
        content: Text(
          'Playing S${episode.seasonNumber} E${episode.episodeNumber} · ${episode.name}',
          style: const TextStyle(color: ColorPalette.fontWhite),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleWatchNow(TvShowDetailInfo info) {
    //debugPrintt('Watch Now triggered for series: ${info.id} (${info.name})');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ColorPalette.surfaceContainerHighest,
        content: Text(
          'Streaming ${info.name}',
          style: const TextStyle(color: ColorPalette.fontWhite),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final initialItem = _resolveMediaItem();

    if (initialItem == null || initialItem.id.trim().isEmpty) {
      return _buildInvalidTvScreen(context);
    }

    final detailsAsync = ref.watch(tvShowDetailsProvider(initialItem));
    final info =
        detailsAsync.value ?? TvShowDetailInfo.fromMediaItem(initialItem);

    final isBookmarked = ref.watch(
      isWatchlistedProvider((mediaType: 'tv', id: initialItem.id)),
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
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 80),
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
    TvShowDetailInfo info,
    MediaItem item,
    bool isBookmarked,
  ) {
    final responsive = context.responsive;
    final heroHeight = (responsive.width * 10 / 16).clamp(240.0, 360.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cinematic Hero Backdrop with Overlaid Back Button & Telemetry
        _buildHeroBackdrop(context, info, item, heroHeight),

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
                info.name,
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

              // Audio Stream Dropdown
              const MovieAudioDropdown(isTvOrDesktop: false),
              const SizedBox(height: 18),

              // Synopsis Section
              _buildSynopsisSection(context, info),
              const SizedBox(height: 24),

              // Divider
              const Divider(color: ColorPalette.ghostBorder, height: 1),
              const SizedBox(height: 20),

              // Episodes Section with Season Selector & Vertical Episode List
              TvEpisodeList(
                seriesId: info.id,
                seasons: info.seasons,
                onEpisodeSelected: (episode) =>
                    _handleEpisodePlayback(episode, info.id),
              ),
              const SizedBox(height: 24),

              // Divider
              const Divider(color: ColorPalette.ghostBorder, height: 1),
              const SizedBox(height: 20),

              // About Section (Telemetry Information Card)
              TvShowInfoMatrix(info: info, isTvOrDesktop: false),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Divider
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: responsive.scale(16, min: 12, max: 20),
          ),
          child: const Divider(color: ColorPalette.ghostBorder, height: 1),
        ),
        const SizedBox(height: 20),

        // Cast & Crew Section
        TvCastSection(seriesId: info.id, isTvOrDesktop: false),

        const SizedBox(height: 24),

        // Similar Shows Section
        SimilarTvShowsSection(seriesId: info.id, isTvOrDesktop: false),

        const SizedBox(height: 20),
      ],
    );
  }

  // ===========================================================================
  // 2. TV & DESKTOP LARGE SCREEN LAYOUT (16:9 Screen Composition)
  // ===========================================================================

  Widget _buildTvLayout(
    BuildContext context,
    TvShowDetailInfo info,
    MediaItem item,
    bool isBookmarked,
  ) {
    final responsive = context.responsive;
    final horizontalPadding = responsive.scale(36.0, min: 28.0, max: 48.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TV Hero Backdrop Section
        Stack(
          children: [
            // Full-width Wide Cinematic Background with poster-to-backdrop smooth transition
            _buildHeroArtwork(
              posterUrl: info.posterUrl ?? item.imageUrl,
              backdropUrl: info.backdropUrl,
              height: 560,
              width: double.infinity,
              alignment: Alignment.topCenter,
            ),

            // Horizontal & Vertical Scrim Gradients
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
                    stops: const [0.0, 0.35, 0.85, 1.0],
                    colors: [
                      ColorPalette.backgroundBlack.withValues(alpha: 0.5),
                      Colors.transparent,
                      ColorPalette.backgroundBlack.withValues(alpha: 0.80),
                      ColorPalette.backgroundBlack,
                    ],
                  ),
                ),
              ),
            ),

            // Back Button at Top Left
            Positioned(
              left: horizontalPadding,
              top: 28,
              child: TvFocusable(
                borderRadius: BorderRadius.circular(24),
                onSelect: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/');
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
                    } else {
                      context.go('/');
                    }
                  },
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                ),
              ),
            ),

            // Live Telemetry Stream Health HUD top right
            Positioned(
              right: horizontalPadding,
              top: 28,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: ColorPalette.backgroundBlack.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: ColorPalette.primaryGreen.withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: ColorPalette.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'HEVC 2160p · HDR10+ · DOLBY ATMOS',
                      style: TextStyle(
                        color: ColorPalette.primaryGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
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

                  // TV Big Screen Title
                  Text(
                    info.name,
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
                        effects: [
                          DpadScaleEffect(scale: 1.05),
                          DpadTintEffect(
                            borderRadius: BorderRadius.circular(50),
                            color: ColorPalette.fontWhite,
                            opacity: 0.2,
                          ),
                        ],
                        onSelect: () => _handleWatchNow(info),
                        child: ElevatedButton.icon(
                          onPressed: () => _handleWatchNow(info),
                          icon: const Icon(
                            Icons.play_arrow_rounded,
                            size: 28,
                            color: Colors.black,
                          ),
                          label: const Text(
                            'Watch Now',
                            style: TextStyle(
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
                      const MovieAudioDropdown(isTvOrDesktop: true),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Two-Column TV Dossier Section: Left Poster + Rich Synopsis, Right Quick Production Highlights
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Poster + Synopsis
              Expanded(
                flex: 7,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vertical 2:3 Poster
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 170,
                        height: 255,
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
                                : 'No synopsis available for this TV series.',
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
                                'SEASONS',
                                info.seasonsFormatted.toUpperCase(),
                                'COMPLETE SERIES',
                              ),
                              const SizedBox(width: 12),
                              _buildTvTelemetryBadge(
                                'DYNAMIC RANGE',
                                '1,000 NITS',
                                'DOLBY VISION',
                              ),
                              const SizedBox(width: 12),
                              _buildTvTelemetryBadge(
                                'AUDIO MASTER',
                                'DOLBY ATMOS',
                                'SPATIAL SOUND',
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

              // Right Column: Summary Card
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: ColorPalette.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: ColorPalette.ghostBorderLight,
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'SHOW INFO',
                            style: TextStyle(
                              color: ColorPalette.fontWhite,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: ColorPalette.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'TMDB-${info.id}',
                              style: const TextStyle(
                                color: ColorPalette.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(color: ColorPalette.ghostBorder, height: 1),
                      const SizedBox(height: 14),

                      _buildDossierRow(
                        'Creators',
                        info.creators.isNotEmpty ? info.creators : 'Various',
                      ),
                      const SizedBox(height: 10),
                      _buildDossierRow(
                        'Status',
                        info.status == "Returning Series"
                            ? "Ongoing"
                            : info.status,
                        isAccent: true,
                      ),
                      const SizedBox(height: 10),
                      _buildDossierRow(
                        'Original Broadcast',
                        info.airYearsFormatted,
                      ),
                      const SizedBox(height: 10),
                      _buildDossierRow('Episodes', info.episodesFormatted),
                      const SizedBox(height: 10),
                      _buildDossierRow(
                        'Original Language',
                        info.originalLanguage,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 36),

        // TV Horizontal Episode Carousel
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: TvEpisodeCarousel(
            seriesId: info.id,
            seasons: info.seasons,
            onEpisodeSelected: (episode) =>
                _handleEpisodePlayback(episode, info.id),
          ),
        ),

        const SizedBox(height: 36),

        // About Breaking Bad (4-column Bento grid)
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: TvShowInfoMatrix(info: info, isTvOrDesktop: true),
        ),

        const SizedBox(height: 36),

        // Section: Cast & Crew
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: TvCastSection(seriesId: info.id, isTvOrDesktop: true),
        ),

        const SizedBox(height: 36),

        // Section: Similar TV Shows
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: SimilarTvShowsSection(seriesId: info.id, isTvOrDesktop: true),
        ),

        const SizedBox(height: 40),
      ],
    );
  }

  // ===========================================================================
  // 3. TABLET LAYOUT
  // ===========================================================================

  Widget _buildTabletLayout(
    BuildContext context,
    TvShowDetailInfo info,
    MediaItem item,
    bool isBookmarked,
  ) {
    final responsive = context.responsive;
    final paddingH = responsive.scale(24.0, min: 20.0, max: 32.0);
    final heroHeight = (responsive.width * 9 / 16).clamp(300.0, 420.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroBackdrop(context, info, item, heroHeight),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: paddingH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                info.name,
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
                  Expanded(flex: 3, child: _buildWatchNowButton(context, info)),
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
                  const Expanded(
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
                    child: TvShowInfoMatrix(info: info, isTvOrDesktop: true),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const Divider(color: ColorPalette.ghostBorder, height: 1),
              const SizedBox(height: 20),
              TvEpisodeList(
                seriesId: info.id,
                seasons: info.seasons,
                onEpisodeSelected: (episode) =>
                    _handleEpisodePlayback(episode, info.id),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        TvCastSection(seriesId: info.id, isTvOrDesktop: false),
        const SizedBox(height: 28),
        SimilarTvShowsSection(seriesId: info.id, isTvOrDesktop: false),
        const SizedBox(height: 24),
      ],
    );
  }

  // ===========================================================================
  // SHARED SUB-WIDGET BUILDERS
  // ===========================================================================

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
              fadeInDuration: const Duration(milliseconds: 600),
              fadeOutDuration: const Duration(milliseconds: 300),
              placeholder: (context, url) => const SizedBox.shrink(),
              errorWidget: (context, url, error) => const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroBackdrop(
    BuildContext context,
    TvShowDetailInfo info,
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

        // Back button matching Movie Details convention
        Positioned(
          left: 20,
          top: topPadding + 8,
          child: IconButton(
            style: IconButton.styleFrom(
              padding: const EdgeInsets.only(left: 8),
              backgroundColor: const Color.fromARGB(62, 255, 255, 255),
            ),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataRow(BuildContext context, TvShowDetailInfo info) {
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
          info.airYearsFormatted,
          style: TextStyle(
            color: ColorPalette.fontWhite,
            fontSize: responsive.sp(13, min: 11, max: 14),
            fontWeight: FontWeight.w600,
          ),
        ),
        _buildDot(),
        Text(
          info.seasonsFormatted,
          style: TextStyle(
            color: ColorPalette.textMuted,
            fontSize: responsive.sp(13, min: 11, max: 14),
          ),
        ),
        _buildDot(),

        // Preserved adult content indicator following project's established conventions
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
        _buildBadge('4K ULTRA', isPrimary: true),
        _buildDot(),
        _buildBadge('Dolby Atmos'),
      ],
    );
  }

  Widget _buildTvMetadataBar(BuildContext context, TvShowDetailInfo info) {
    final ratingVal = info.rating != null
        ? info.rating!.toStringAsFixed(1)
        : '8.0';

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Text(
          info.airYearsFormatted,
          style: const TextStyle(
            color: ColorPalette.fontWhite,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        _buildTvDot(),
        Text(
          info.seasonsFormatted,
          style: const TextStyle(color: ColorPalette.textMuted, fontSize: 16),
        ),
        _buildTvDot(),
        _buildBadge(info.isAdult ? 'Adult 18+' : 'Not Adult'),
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
                  '(${info.ratingCount})',
                  style: const TextStyle(
                    color: ColorPalette.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
        _buildBadge('4K ULTRA', isPrimary: true),
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
    TvShowDetailInfo info,
    MediaItem item,
    bool isBookmarked,
  ) {
    return Row(
      children: [
        Expanded(child: _buildWatchNowButton(context, info)),
        const SizedBox(width: 10),
        _buildGhostButton(
          icon: isBookmarked ? Icons.bookmark_added_rounded : Icons.add_rounded,
          label: isBookmarked ? 'In My List' : 'My List',
          isBookmarked: isBookmarked,
          onTap: () => _toggleWatchlist(info, item),
        ),
      ],
    );
  }

  Widget _buildWatchNowButton(BuildContext context, TvShowDetailInfo info) {
    return ElevatedButton.icon(
      onPressed: () => _handleWatchNow(info),
      icon: const Icon(Icons.play_arrow_rounded, size: 24, color: Colors.black),
      label: const Text(
        'Watch Now',
        style: TextStyle(
          color: Colors.black,
          fontSize: 15,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
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

  Widget _buildSynopsisSection(BuildContext context, TvShowDetailInfo info) {
    final responsive = context.responsive;
    final overviewText = info.overview?.isNotEmpty == true
        ? info.overview!
        : 'Follow the compelling episodic journey in this acclaimed television series.';

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
          fontSize: 11,
          fontWeight: FontWeight.w700,
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
      width: 4,
      height: 4,
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
        color: ColorPalette.surfaceContainerHigh,
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
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: ColorPalette.fontWhite,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            sub,
            style: const TextStyle(
              color: ColorPalette.primaryGreen,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDossierRow(String label, String value, {bool isAccent = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: ColorPalette.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),

        Flexible(
          child: Text(
            value,
            softWrap: true,
            style: TextStyle(
              color: isAccent
                  ? ColorPalette.primaryGreen
                  : ColorPalette.fontWhite,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInvalidTvScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.backgroundBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.tv_off_rounded,
              size: 54,
              color: ColorPalette.error,
            ),
            const SizedBox(height: 16),
            const Text(
              'TV Show data unavailable',
              style: TextStyle(
                color: ColorPalette.fontWhite,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Could not load the requested series.',
              style: TextStyle(color: ColorPalette.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go('/'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPalette.primaryGreen,
              ),
              child: const Text(
                'Return Home',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
