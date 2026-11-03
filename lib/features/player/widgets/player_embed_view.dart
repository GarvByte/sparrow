import 'package:flutter/material.dart';

import 'player_embed_view_stub.dart'
    if (dart.library.io) 'player_embed_view_native.dart'
    if (dart.library.html) 'player_embed_view_web.dart';

class PlayerEmbedView extends StatelessWidget {
  final String url;

  const PlayerEmbedView({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return buildPlayerEmbedView(url);
  }
}
