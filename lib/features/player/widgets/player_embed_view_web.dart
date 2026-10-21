import 'dart:html' as html;
import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';

// import 'package:flutter/material.dart';

Widget buildPlayerEmbedView(String url) {
  final iframe = html.IFrameElement()
    ..src = url
    ..style.border = '0'
    ..style.width = '100%'
    ..style.height = '100%'
    ..allow = 'autoplay; fullscreen; picture-in-picture'
    ..allowFullscreen = true;

  final viewType = 'nxsha-embed-${url.hashCode}';

  ui.platformViewRegistry.registerViewFactory(
    viewType,
    (int viewId) => iframe,
  );

  return HtmlElementView(viewType: viewType);
}
