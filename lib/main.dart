import 'package:dpad/dpad.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// ignore: depend_on_referenced_packages
import 'package:material_ui/material_ui.dart' as mui;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparrow/navigation/dpad_shortcut.dart';
import 'features/continue_watching/data/continue_watching_storage.dart';
import 'features/player/services/stream_cache_service.dart';
import 'features/watchlist/data/watchlist_storage.dart';
import 'navigation/app_router.dart';
import 'theme/color_palette.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  await WatchlistStorage.init();
  await ContinueWatchingStorage.init();
  await StreamCacheService.init();

  // Conservative image cache limits (35 MB max, 60 images) to prevent LMK kills on 1-2 GB Fire TV devices
  PaintingBinding.instance.imageCache.maximumSizeBytes = 35 * 1024 * 1024;
  PaintingBinding.instance.imageCache.maximumSize = 60;

  runApp(const SparrowApp());
}

class SparrowApp extends StatelessWidget {
  const SparrowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp.router(
      localizationsDelegates: [
        mui.GlobalMaterialLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
      ],
      title: 'Sparrow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: ColorPalette.backgroundBlack,
        colorScheme: const ColorScheme.dark(
          primary: ColorPalette.primaryGreen,
          secondary: ColorPalette.primaryGreen,
          surface: ColorPalette.surface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: ColorPalette.backgroundBlack,
          elevation: 0,
        ),
      ),
      routerConfig: appRouter,
      builder: (context, child) {
        return Dpad.wrap(debugOverlay: false)(
          context,
          AppBackShortcuts(child: child ?? const SizedBox.shrink()),
        );
      },
      scrollBehavior: const CustomScrollBehavior(),
    ),
    );
  }
}

class CustomScrollBehavior extends MaterialScrollBehavior {
  const CustomScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.mouse,
    PointerDeviceKind.touch,
  };
}
