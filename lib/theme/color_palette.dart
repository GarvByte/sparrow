import 'package:flutter/material.dart';

class ColorPalette {
  // Original theme colors preserved strictly
  static const Color primaryGreen = Color(0xFF1DB954);
  static const Color backgroundBlack = Color.fromARGB(255, 0, 0, 0);
  static const Color secondaryBrown = Color.fromARGB(255, 46, 12, 0);
  static const Color fontWhite = Color.fromARGB(255, 255, 255, 255);

  // Surface and atmospheric depths from Obsidian Emerald design system
  static const Color canvas = Color(0xFF090B0A);
  static const Color surface = Color(0xFF121413);
  static const Color surfaceContainerLow = Color(0xFF1A1C1B);
  static const Color surfaceContainer = Color(0xFF1E201F);
  static const Color surfaceContainerHigh = Color(0xFF282A29);
  static const Color surfaceContainerHighest = Color(0xFF333534);

  // Cinematic Hero tones (Refined dark muted brown #281913 container)
  static const Color heroContainer = Color(0xFF281913);
  static const Color heroBorder = Color(0xFF3E2B22);
  static const Color heroChipBackground = Color(0xFF38231B);

  // Text & muted tones
  static const Color textPrimary = Color(0xFFF5F7F5);
  static const Color textMuted = Color(0xFFA1AAA4);
  static const Color textSecondary = Color(0xFFBCCBB9);

  // Border scrims
  static const Color ghostBorder = Color(0x1FFFFFFF); // 12% white outline
  static const Color ghostBorderLight = Color(0x28FFFFFF); // 16% white outline

  //error widgets
  static const Color error = Color.fromARGB(255, 216, 14, 0);
  static const Color placeholder = Color.fromARGB(255, 111, 111, 111);

  //gradiant
  static const Color gradientEnd = Color.fromARGB(255, 0, 53, 2);
}
