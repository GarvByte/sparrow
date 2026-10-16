import 'package:flutter/material.dart';
import 'package:sparrow/shared/responsive_utils.dart';
import 'package:sparrow/theme/color_palette.dart';

class ErrorImagePlaceholder extends StatelessWidget {
  const ErrorImagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return Container(
      color: ColorPalette.placeholder,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: ColorPalette.error),
            Text(
              "Poster unavailable",
              style: TextStyle(
                color: ColorPalette.textSecondary,
                fontSize: responsive.sp(10, min: 8.5, max: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
