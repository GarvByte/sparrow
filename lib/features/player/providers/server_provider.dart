import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/media_item.dart';
import '../data/server_list.dart';
import '../models/playback_context.dart';
import '../services/nxsha_api_service.dart';
import '../services/nxsha_cipher.dart';

/// Legacy provider kept for backward compatibility.
/// Delegates to [NxshaCipher] and [NxshaApiService].
class ServerProvider extends Notifier<dynamic> {
  final NxshaApiService _apiService = NxshaApiService();

  @override
  dynamic build() {
    return null;
  }

  String buildPayload({
    required String tmdbId,
    required String imdbId,
    required String type,
    required dynamic season,
    required dynamic episode,
  }) {
    final s = season is int ? season : int.tryParse(season.toString()) ?? 0;
    final e = episode is int ? episode : int.tryParse(episode.toString()) ?? 0;
    return NxshaCipher.buildPayload(
      tmdbId: tmdbId,
      imdbId: imdbId,
      type: type,
      season: s,
      episode: e,
    );
  }

  Future<Map<String, dynamic>?> fetchData({
    required String tmdbId,
    required String imdbId,
    required String type,
    int season = 0,
    int episode = 0,
  }) async {
    try {
      final context = PlaybackContext(
        item: const MediaItem(id: '0', title: '', imageUrl: '', genres: []),
        tmdbId: tmdbId,
        imdbId: imdbId,
        isTvShow: type == 'tv',
        season: season,
        episode: episode,
      );

      final servers = await _apiService.fetchServers(context);
      serversList = servers.map((s) => s.toJson()).toList();
      state = {'servers': serversList};
      return state as Map<String, dynamic>;
    } catch (e) {
      debugPrint('ServerProvider.fetchData error: $e');
      return null;
    }
  }
}

final serverNotifier = NotifierProvider<ServerProvider, dynamic>(() {
  return ServerProvider();
});
