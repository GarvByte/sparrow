// import 'package:flutter/foundation.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:http/http.dart' as http;

// class EmbedMovies extends Notifier<void> {
//   @override
//   void build() {
//     return;
//   }

//   Future<dynamic> fetchMovieEmbed(id) async {
//     try {
//       final movieEmbedUrl =
//           "https://nxsha.space/embed/movie/$id?color=%231DB954?lang=hi?sub=en?disable_dl_button=true?disable_app_ad=true";
//       final response = http.get(Uri.parse(movieEmbedUrl));
//       return response;
//     } catch (e) {
//       debugPrint("Error in movie embed: $e");
//       return e;
//     }
//   }
// }

class NxshaEmbedUrl {
  static Uri movie({
    required String tmdbId,
    String language = 'hi',
    String subtitle = 'en',
  }) {
    return Uri.https(
      'nxsha.space',
      '/embed/movie/$tmdbId',
      {
        'color': '#1DB954',
        'lang': language,
        'sub': subtitle,
        'disable_dl_button': 'true',
        'disable_app_ad': 'true',
      },
    );
  }
}