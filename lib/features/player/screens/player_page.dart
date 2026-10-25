// import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:sparrow/shared/media_item.dart';
import 'package:better_player_plus/better_player_plus.dart';

// import 'package:flutter_riverpod/flutter_riverpod.dart';

// import 'package:sparrow/features/player/providers/embed_movies.dart';
// import 'package:sparrow/features/player/widgets/player_embed_view.dart';
// import 'package:sparrow/shared/media_item.dart';
// import 'package:sparrow/theme/color_palette.dart';

// class PlayerPage extends ConsumerWidget {
//   final MediaItem item;

//   const PlayerPage({super.key, required this.item});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final embedUrl = NxshaEmbedUrl.movie(tmdbId: item.id).toString();

//     return Scaffold(
//       backgroundColor: ColorPalette.backgroundBlack,
//       appBar: AppBar(
//         title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
//       ),
//       body: SingleChildScrollView(
//         child: Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               AspectRatio(
//                 aspectRatio: 16 / 9,
//                 child: PlayerEmbedView(url: embedUrl),
//               ),
//               Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Text(
//                   item.title,
//                   style: const TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key, required this.item});
  final MediaItem item;

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late BetterPlayerController controller;

  @override
  void initState() {
    super.initState();

    final dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      "https://wts.itsnitrox.tech/nitro/3d55444e32636a4d3549544f3345545034746d4a6e6447543263555a786f335a6642335970396d533351444e4d6c446532307a612f6754647a306d4c7a4d7a4d7a6b7a4e33677a4e783469636c5233636831324c686458633463334c78676a6376556d6376523363754d3361793932646c5a58613046575a794e475a735657616d563263704a6e62314e6e4c754633637677476376516a6476554764704e6e4c6956486174426e63754d585a705a3362746c4764735658627638694f7a424864306857656c7432586c4a58646a56326366686e62/master.m3u8",
      headers: {"Referer": "https://nxsha.space/"}
    );

    controller = BetterPlayerController(
      const BetterPlayerConfiguration(
        autoPlay: false,
        aspectRatio: 16 / 9,
        fit: BoxFit.contain,
      ),
      betterPlayerDataSource: dataSource,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${widget.item.title}m3u8",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: BetterPlayer(controller: controller),
        ),
      ),
    );
  }
}
