import 'package:flutter/material.dart';

/// Centralized responsive layout and sizing system for Sparrow.
///
/// Designed to adapt typography, icons, card sizes, and touch targets
/// across small phones, standard Android devices, tablets, and Android TV
/// without unbounded or blind multiplier scaling.
class SparrowResponsive {
  final BuildContext context;
  final MediaQueryData mediaQuery;

  SparrowResponsive(this.context) : mediaQuery = MediaQuery.of(context);

  Size get size => mediaQuery.size;
  double get width => size.width;
  double get height => size.height;
  EdgeInsets get padding => mediaQuery.padding;
  EdgeInsets get viewInsets => mediaQuery.viewInsets;

  /// Height available excluding system status bar and navigation bar.
  double get safeHeight =>
      (height - padding.top - padding.bottom).clamp(100.0, double.infinity);

  /// Device classification
  bool get isSmallPhone => width < 360 || height < 700;
  bool get isNormalPhone => width >= 360 && width < 600;
  bool get isTablet =>
      (mediaQuery.size.shortestSide >= 600 && !isTvOrDesktop) ||
      (width >= 600 && width < 1024 && !isTvOrDesktop);
  bool get isTvOrDesktop =>
      width >= 1024 ||
      (isLandscape && width >= 900 && mediaQuery.size.shortestSide >= 500);
  bool get isLandscape => width > height;

  /// Whether the device is a mobile phone (shortest side < 600dp and not a TV/desktop).
  bool get isPhone => mediaQuery.size.shortestSide < 600 && !isTvOrDesktop;

  /// Width scale factor relative to standard 390dp baseline, clamped to prevent
  /// extremes on very small phones or wide TV/tablet screens.
  double get widthScale {
    final raw = width / 390.0;
    return raw.clamp(0.85, 1.30);
  }

  /// Height scale factor relative to 844dp baseline.
  double get heightScale {
    final raw = height / 844.0;
    return raw.clamp(0.80, 1.25);
  }

  /// Scale a dimensional value (width, padding, margin) proportionally.
  double scale(double value, {double min = 0.0, double max = double.infinity}) {
    return (value * widthScale).clamp(min, max);
  }

  /// Scale vertically based on screen height.
  double scaleY(
    double value, {
    double min = 0.0,
    double max = double.infinity,
  }) {
    return (value * heightScale).clamp(min, max);
  }

  /// Scaled font size with accessibility text scaling awareness.
  double sp(double baseSize, {double min = 9.0, double max = 34.0}) {
    final scaled = baseSize * (isTvOrDesktop ? 1.20 : widthScale);
    final textScale = mediaQuery.textScaler.scale(1.0).clamp(0.85, 1.30);
    return (scaled * textScale).clamp(min, max);
  }

  /// Responsive icon size with accessible constraints.
  double iconSize(double baseSize, {double min = 14.0, double max = 36.0}) {
    final scaled = baseSize * (isTvOrDesktop ? 1.20 : widthScale);
    return scaled.clamp(min, max);
  }

  /// Responsive corner radius.
  double radius(double baseRadius) {
    return (baseRadius * widthScale).clamp(baseRadius * 0.8, baseRadius * 1.25);
  }

  /// Minimum accessible touch target (48dp standard).
  double touchTarget(double baseSize) => baseSize < 48.0 ? 48.0 : baseSize;

  // ---------------------------------------------------------------------------
  // Featured Layered Hero Dimensions (Each Movie Card in Rounded Brown Container)
  // ---------------------------------------------------------------------------

  /// Total target height for each Featured Movie Card (60%–68% of available safeHeight).
  double get heroCardHeight {
    if (isTvOrDesktop) {
      return (safeHeight * 0.58).clamp(560.0, 760.0);
    }
    final factor = isSmallPhone ? 0.60 : 0.66;
    return (safeHeight * factor).clamp(360.0, 520.0);
  }

  /// Backward-compatibility alias for heroCardHeight.
  double get heroSectionHeight => heroCardHeight;

  /// Responsive corner radius for each movie's brown container (24-30 logical pixels).
  double get heroContainerRadius => scale(26.0, min: 22.0, max: 28.0);

  /// Height for the active 17:16 poster inside each movie card.
  /// Exactly 17:16 aspect ratio: width = height * (17 / 16).
  double get heroPosterHeight {
    // Reserve vertical space inside the card for padding, title, genres, rating, and watch button
    final reservedForMetadata = isSmallPhone
        ? 152.0
        : (isTvOrDesktop ? 165.0 : 152.0);
    final available = heroCardHeight - reservedForMetadata;

    if (isTvOrDesktop) {
      return available.clamp(250.0, 350.0);
    }
    return available.clamp(isSmallPhone ? 148.0 : 160.0, 280.0);
  }

  /// Active poster width derived strictly from the 17:16 aspect ratio.
  double get heroPosterWidth => heroPosterHeight * (17.0 / 16.0);

  /// Height of the carousel slider accommodating the active card plus vertical drop of side cards.
  double get layeredCarouselHeight =>
      heroCardHeight + (isSmallPhone ? 16.0 : 20.0);

  // ---------------------------------------------------------------------------
  // Content Carousels Responsive Sizing
  // ---------------------------------------------------------------------------

  double get continueWatchingWidth => scale(250.0, min: 200.0, max: 320.0);
  double get continueWatchingHeight => (continueWatchingWidth * 9 / 16) + 4.0;

  double get trendingPosterWidth => scale(165.0, min: 135.0, max: 210.0);
  double get trendingPosterHeight => (trendingPosterWidth * 1.5) + 4.0;

  double get hindiPosterWidth => scale(140.0, min: 115.0, max: 180.0);
  double get hindiPosterHeight => (hindiPosterWidth * 1.5) + 4.0;

  double get animePosterWidth => scale(155.0, min: 125.0, max: 190.0);
  double get animePosterHeight => (animePosterWidth * 1.5) + 4.0;

  double get blockbusterWidth => scale(230.0, min: 185.0, max: 290.0);
  double get blockbusterHeight => (blockbusterWidth * 9 / 16) + 4.0;

  // ---------------------------------------------------------------------------
  // Navigation & Headers
  // ---------------------------------------------------------------------------

  double get headerHeight => scale(62.0, min: 54.0, max: 70.0);
  double get bottomNavHeight => scale(62.0, min: 54.0, max: 70.0);
  double get bottomNavMaxWidth =>
      isTvOrDesktop || isTablet ? 460.0 : (width - 32.0);
}

extension SparrowResponsiveExtension on BuildContext {
  SparrowResponsive get responsive => SparrowResponsive(this);
}
