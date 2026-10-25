import 'package:dpad/dpad.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparrow/navigation/dpad_shortcut.dart';
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
  PaintingBinding.instance.imageCache.maximumSizeBytes = 150 * 1024 * 1024;
  runApp(const ProviderScope(child: SparrowApp()));
}


class SparrowApp extends StatelessWidget {
  const SparrowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp.router(
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
