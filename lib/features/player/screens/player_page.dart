import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sparrow/features/player/providers/embed_movies.dart';
import 'package:sparrow/features/player/widgets/player_embed_view.dart';
import 'package:sparrow/shared/media_item.dart';
import 'package:sparrow/theme/color_palette.dart';

class PlayerPage extends ConsumerWidget {
  final MediaItem item;

  const PlayerPage({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final embedUrl = NxshaEmbedUrl.movie(tmdbId: item.id).toString();

    return Scaffold(
      backgroundColor: ColorPalette.backgroundBlack,
      appBar: AppBar(
        title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: SingleChildScrollView(
        child: Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: PlayerEmbedView(url: embedUrl),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
