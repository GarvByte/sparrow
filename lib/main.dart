import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/home page/screen/home_page.dart';
import 'theme/color_palette.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(
    const ProviderScope(
      child: SparrowApp(),
    ),
  );
}

class SparrowApp extends StatelessWidget {
  const SparrowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
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
      home: const HomePage(),
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
