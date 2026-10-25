import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

Widget buildPlayerEmbedView(String url) {
  return InAppWebView(
    initialUrlRequest: URLRequest(
      url: WebUri(url),
    ),
    initialSettings: InAppWebViewSettings(
      javaScriptEnabled: true,
      domStorageEnabled: true,
      mediaPlaybackRequiresUserGesture: false,
      allowsInlineMediaPlayback: true,
    ),
  );
}