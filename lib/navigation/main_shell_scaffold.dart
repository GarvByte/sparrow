import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sparrow/features/home%20page/widgets/floating_bottom_nav.dart';
import 'package:sparrow/theme/color_palette.dart';

/// Top-level shell scaffold that hosts the [StatefulNavigationShell] and
/// the floating bottom navigation bar dock.
class MainShellScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.backgroundBlack,
      body: Stack(
        children: [
          // The current active branch from the indexed stack
          navigationShell,

          // Shared floating bottom navigation dock preserved from home page
          FloatingBottomNav(
            currentIndex: navigationShell.currentIndex,
            onTabSelected: (index) {
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
          ),
        ],
      ),
    );
  }
}

/// A placeholder screen for secondary tabs (Anime, Profile)
class TabPlaceholderPage extends StatelessWidget {
  final String title;
  final IconData icon;

  const TabPlaceholderPage({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.backgroundBlack,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [ColorPalette.backgroundBlack, ColorPalette.gradientEnd],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: ColorPalette.surfaceContainer,
                  shape: BoxShape.circle,
                  border: Border.all(color: ColorPalette.ghostBorder),
                ),
                child: Icon(icon, size: 34, color: ColorPalette.primaryGreen),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  color: ColorPalette.fontWhite,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Coming soon in the next release',
                style: TextStyle(color: ColorPalette.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
