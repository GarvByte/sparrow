import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/server_list.dart';
import '../models/playback_context.dart';
import '../models/resolved_source.dart';
import '../models/server_item.dart';
import '../repositories/stream_repository.dart';

final streamRepositoryProvider = Provider<StreamRepository>((ref) {
  return StreamRepository();
});

class StreamResolutionState {
  final PlaybackContext? context;
  final List<ServerItem> servers;
  final int? selectedServerIndex;
  final int? selectedSourceIndex;
  final ResolvedSource? currentSource;
  final bool isLoadingServers;
  final bool isResolvingFirstSource;
  final bool isResolvingBackground;
  final String statusMessage;
  final String? errorMessage;
  final int fallbackAttempts;

  const StreamResolutionState({
    this.context,
    this.servers = const [],
    this.selectedServerIndex,
    this.selectedSourceIndex,
    this.currentSource,
    this.isLoadingServers = false,
    this.isResolvingFirstSource = false,
    this.isResolvingBackground = false,
    this.statusMessage = '',
    this.errorMessage,
    this.fallbackAttempts = 0,
  });

  StreamResolutionState copyWith({
    PlaybackContext? context,
    List<ServerItem>? servers,
    int? selectedServerIndex,
    int? selectedSourceIndex,
    ResolvedSource? currentSource,
    bool? isLoadingServers,
    bool? isResolvingFirstSource,
    bool? isResolvingBackground,
    String? statusMessage,
    String? errorMessage,
    bool clearError = false,
    int? fallbackAttempts,
  }) {
    return StreamResolutionState(
      context: context ?? this.context,
      servers: servers ?? this.servers,
      selectedServerIndex: selectedServerIndex ?? this.selectedServerIndex,
      selectedSourceIndex: selectedSourceIndex ?? this.selectedSourceIndex,
      currentSource: currentSource ?? this.currentSource,
      isLoadingServers: isLoadingServers ?? this.isLoadingServers,
      isResolvingFirstSource:
          isResolvingFirstSource ?? this.isResolvingFirstSource,
      isResolvingBackground:
          isResolvingBackground ?? this.isResolvingBackground,
      statusMessage: statusMessage ?? this.statusMessage,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      fallbackAttempts: fallbackAttempts ?? this.fallbackAttempts,
    );
  }

  ServerItem? get selectedServer {
    if (selectedServerIndex != null &&
        selectedServerIndex! >= 0 &&
        selectedServerIndex! < servers.length) {
      return servers[selectedServerIndex!];
    }
    return null;
  }

  List<ResolvedSource> get currentServerSources {
    return selectedServer?.sources ?? [];
  }
}

class StreamResolutionNotifier extends Notifier<StreamResolutionState> {
  late final StreamRepository _repository;
  bool _disposed = false;
  int _currentSessionId = 0;

  @override
  StreamResolutionState build() {
    _repository = ref.watch(streamRepositoryProvider);
    ref.onDispose(() {
      _disposed = true;
    });
    return const StreamResolutionState();
  }

  List<ResolvedSource> _sortSourcesByLanguage(List<ResolvedSource> sources) {
    final list = List<ResolvedSource>.from(sources);
    list.sort((a, b) {
      int priority(ResolvedSource s) {
        if (s.language == SourceLanguage.hindi) return 0;
        if (s.language == SourceLanguage.multi) return 1;
        if (s.language == SourceLanguage.english) return 2;
        if (s.language == SourceLanguage.unknown) return 3;
        return 4;
      }

      final pA = priority(a);
      final pB = priority(b);
      if (pA != pB) return pA.compareTo(pB);
      return 0; // Preserve existing quality ranking
    });
    return list;
  }

  /// Cancels any active resolution/background session and resets the controller state.
  /// Called when player page disposes to isolate playback sessions.
  void cancelSession() {
    _currentSessionId++;
    try {
      if (ref.mounted) {
        state = const StreamResolutionState();
      }
    } catch (_) {}
  }

  /// Concurrently preloads the server list when details page opens.
  /// Does not block details page and caches the result safely in the repository.
  Future<void> preloadServers(PlaybackContext context) async {
    // Avoid re-fetching if already loaded for this exact context
    if (state.context == context && state.servers.isNotEmpty) {
      return;
    }

    try {
      final servers = await _repository.getServers(context);
      if (_disposed) return;

      // Update legacy server_list for safety
      serversList = servers.map((s) => s.toJson()).toList();

      // Only update state if not currently playing a different movie/show
      if (state.context == null ||
          state.context == context ||
          !state.isResolvingFirstSource) {
        state = StreamResolutionState(
          context: context,
          servers: servers,
        );
      }
    } catch (e) {
      debugPrint('Preload servers failed silently (details page unblocked): $e');
    }
  }

  /// Initiates complete stream resolution for playback:
  /// 1. Enforces strict session isolation with a new unique session ID.
  /// 2. Clears any residual state from previous movies/shows immediately.
  /// 3. Resolves and starts the first playable server.
  /// 4. Continues background preparation isolated to this exact session.
  Future<void> startPlaybackResolution({
    required PlaybackContext context,
    required void Function(ResolvedSource source, Duration startAt)
        onSourceReady,
  }) async {
    _currentSessionId++;
    final sessionId = _currentSessionId;

    // Immediately isolate state to the current context, wiping previous movie's servers/sources
    state = StreamResolutionState(
      context: context,
      servers: const [],
      selectedServerIndex: null,
      selectedSourceIndex: null,
      currentSource: null,
      isLoadingServers: true,
      isResolvingFirstSource: true,
      statusMessage: 'Locating streaming servers...',
      errorMessage: null,
      fallbackAttempts: 0,
    );

    List<ServerItem> serverList;
    try {
      serverList = await _repository.getServers(context);
      if (_disposed || _currentSessionId != sessionId) return;

      serversList = serverList.map((s) => s.toJson()).toList();
      state = state.copyWith(
        servers: serverList,
        isLoadingServers: false,
      );
    } catch (e) {
      if (_disposed || _currentSessionId != sessionId) return;
      debugPrint('StreamResolutionNotifier: getServers error: $e');
      final msg =
          _isNetworkError(e) ? 'Check your connection' : 'No sources found';
      state = state.copyWith(
        isLoadingServers: false,
        isResolvingFirstSource: false,
        errorMessage: msg,
      );
      return;
    }

    // Filter playable servers
    final playableIndices = <int>[];
    for (int i = 0; i < serverList.length; i++) {
      if (serverList[i].isPlayable) {
        playableIndices.add(i);
      }
    }

    if (serverList.isEmpty) {
      if (_disposed || _currentSessionId != sessionId) return;
      state = state.copyWith(
        isResolvingFirstSource: false,
        errorMessage: 'No sources found',
      );
      return;
    }

    if (playableIndices.isEmpty) {
      if (_disposed || _currentSessionId != sessionId) return;
      state = state.copyWith(
        isResolvingFirstSource: false,
        errorMessage: 'No playable sources found',
      );
      return;
    }

    // Attempt first playable server first
    bool foundFirstSource = false;
    for (final index in playableIndices) {
      if (_disposed || _currentSessionId != sessionId) return;
      final server = serverList[index];

      state = state.copyWith(
        statusMessage: 'Connecting to ${server.name}...',
        selectedServerIndex: index,
      );

      _updateServerStatus(index, ServerResolutionStatus.loading,
          sessionId: sessionId);

      try {
        final sources = await _repository.getSources(context, server.scraper);
        if (_disposed || _currentSessionId != sessionId) return;

        if (sources.isNotEmpty && sources.any((s) => s.isValidUrl)) {
          // Success! Prioritize Hindi primary, English secondary
          final prioritizedSources = _sortSourcesByLanguage(sources);
          _updateServerSources(
              index, prioritizedSources, ServerResolutionStatus.ready, sessionId);
          sourcesList = prioritizedSources.map((s) => s.toJson()).toList();

          final chosenSource = prioritizedSources.firstWhere((s) => s.isValidUrl);

          state = state.copyWith(
            selectedServerIndex: index,
            selectedSourceIndex: prioritizedSources.indexOf(chosenSource),
            currentSource: chosenSource,
            isResolvingFirstSource: false,
            statusMessage: 'Starting playback from ${server.name}...',
            clearError: true,
          );

          foundFirstSource = true;
          onSourceReady(chosenSource, Duration.zero);

          // Launch background resolution for 2-3 additional servers tied to this session
          _startBackgroundSourceResolution(context, sessionId, index);
          break;
        } else {
          _updateServerStatus(index, ServerResolutionStatus.failed,
              errorMessage: 'No playable links returned.', sessionId: sessionId);
        }
      } catch (e) {
        if (_disposed || _currentSessionId != sessionId) return;
        _updateServerStatus(index, ServerResolutionStatus.failed,
            errorMessage: e.toString(), sessionId: sessionId);
      }
    }

    if (!foundFirstSource && !_disposed && _currentSessionId == sessionId) {
      state = state.copyWith(
        isResolvingFirstSource: false,
        errorMessage: 'Unable to start playback',
      );
    }
  }

  /// Resolves additional alternatives in the background targeting 3-4 ready servers in total.
  /// Strictly checks [sessionId] and [context] to prevent cross-movie contamination.
  void _startBackgroundSourceResolution(
    PlaybackContext context,
    int sessionId,
    int skipIndex,
  ) async {
    if (state.isResolvingBackground || _disposed) return;

    state = state.copyWith(isResolvingBackground: true);

    int readyCount = state.servers.where((s) => s.isReady).length;
    const maxTargetReady = 4;

    for (int i = 0; i < state.servers.length; i++) {
      if (_disposed ||
          _currentSessionId != sessionId ||
          state.context != context ||
          readyCount >= maxTargetReady) {
        debugPrint(
            'StreamResolutionNotifier: Aborting background resolution for obsolete session');
        break;
      }
      if (i == skipIndex) continue;

      final server = state.servers[i];
      if (!server.isPlayable ||
          server.resolutionStatus == ServerResolutionStatus.ready) {
        continue;
      }

      _updateServerStatus(i, ServerResolutionStatus.loading,
          sessionId: sessionId);

      try {
        final sources = await _repository.getSources(context, server.scraper);
        if (_disposed ||
            _currentSessionId != sessionId ||
            state.context != context) {
          return;
        }

        if (sources.isNotEmpty && sources.any((s) => s.isValidUrl)) {
          final prioritizedSources = _sortSourcesByLanguage(sources);
          _updateServerSources(
              i, prioritizedSources, ServerResolutionStatus.ready, sessionId);
          readyCount++;
        } else {
          _updateServerStatus(i, ServerResolutionStatus.failed,
              errorMessage: 'No links', sessionId: sessionId);
        }
      } catch (e) {
        if (_disposed ||
            _currentSessionId != sessionId ||
            state.context != context) {
          return;
        }
        _updateServerStatus(i, ServerResolutionStatus.failed,
            errorMessage: e.toString(), sessionId: sessionId);
      }

      // Small pause between background requests to preserve device I/O & bandwidth
      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (!_disposed && _currentSessionId == sessionId) {
      state = state.copyWith(isResolvingBackground: false);
    }
  }

  /// Switches to another server selected by the user.
  /// If already ready, switches immediately.
  /// If not ready, resolves on demand.
  Future<void> selectServer(
    int serverIndex, {
    required Duration currentPosition,
    required void Function(ResolvedSource source, Duration startAt)
        onSourceReady,
  }) async {
    if (serverIndex < 0 || serverIndex >= state.servers.length) return;
    final server = state.servers[serverIndex];
    final context = state.context;
    if (context == null) return;
    final sessionId = _currentSessionId;

    if (server.isReady) {
      final chosen = server.sources.firstWhere(
        (s) => !s.isFailed && s.isValidUrl,
        orElse: () => server.sources.first,
      );

      state = state.copyWith(
        selectedServerIndex: serverIndex,
        selectedSourceIndex: server.sources.indexOf(chosen),
        currentSource: chosen,
        statusMessage: 'Switched to ${server.name}',
        clearError: true,
      );
      sourcesList = server.sources.map((s) => s.toJson()).toList();
      onSourceReady(chosen, currentPosition);
      return;
    }

    // Resolve on demand
    _updateServerStatus(serverIndex, ServerResolutionStatus.loading,
        sessionId: sessionId);
    state = state.copyWith(
      statusMessage: 'Resolving ${server.name}...',
      clearError: true,
    );

    try {
      final sources = await _repository.getSources(context, server.scraper);
      if (_disposed || _currentSessionId != sessionId) return;

      if (sources.isNotEmpty && sources.any((s) => s.isValidUrl)) {
        final prioritizedSources = _sortSourcesByLanguage(sources);
        _updateServerSources(
            serverIndex, prioritizedSources, ServerResolutionStatus.ready, sessionId);
        sourcesList = prioritizedSources.map((s) => s.toJson()).toList();

        final chosen = prioritizedSources.firstWhere((s) => s.isValidUrl);

        state = state.copyWith(
          selectedServerIndex: serverIndex,
          selectedSourceIndex: prioritizedSources.indexOf(chosen),
          currentSource: chosen,
          statusMessage: 'Playing from ${server.name}',
          clearError: true,
        );

        onSourceReady(chosen, currentPosition);
      } else {
        _updateServerStatus(serverIndex, ServerResolutionStatus.failed,
            errorMessage: 'No playable sources found', sessionId: sessionId);
        state = state.copyWith(
          errorMessage: 'No playable sources found',
        );
      }
    } catch (e) {
      if (_disposed || _currentSessionId != sessionId) return;
      debugPrint('StreamResolutionNotifier: selectServer failed: $e');
      _updateServerStatus(serverIndex, ServerResolutionStatus.failed,
          errorMessage: e.toString(), sessionId: sessionId);
      final msg =
          _isNetworkError(e) ? 'Check your connection' : 'Unable to start playback';
      state = state.copyWith(
        errorMessage: msg,
      );
    }
  }

  /// Switches to another link from the currently selected server.
  void selectSource(
    int sourceIndex, {
    required Duration currentPosition,
    required void Function(ResolvedSource source, Duration startAt)
        onSourceReady,
  }) {
    final server = state.selectedServer;
    if (server == null ||
        sourceIndex < 0 ||
        sourceIndex >= server.sources.length) {
      return;
    }

    var chosen = server.sources[sourceIndex];
    if (!chosen.isValidUrl) return;

    // If the user manually selects a source that was previously marked failed,
    // reset its failed flag so the user can retry it cleanly.
    if (chosen.isFailed) {
      chosen = chosen.copyWith(isFailed: false);
      final updatedSources = List<ResolvedSource>.from(server.sources);
      updatedSources[sourceIndex] = chosen;
      _updateServerSources(state.selectedServerIndex!, updatedSources,
          ServerResolutionStatus.ready, _currentSessionId);
    }

    state = state.copyWith(
      selectedSourceIndex: sourceIndex,
      currentSource: chosen,
      statusMessage: 'Switched to ${chosen.displayName}',
      clearError: true,
    );

    onSourceReady(chosen, currentPosition);
  }

  bool _isNetworkError(Object error) {
    final str = error.toString().toLowerCase();
    return str.contains('socketexception') ||
        str.contains('connection refused') ||
        str.contains('connection timed out') ||
        str.contains('network error') ||
        str.contains('failed host lookup') ||
        str.contains('clientexception') ||
        str.contains('connection closed') ||
        str.contains('timeoutexception');
  }

  /// Automatic fallback handler when playback reports a failure or exception.
  Future<void> handleSourceFailure({
    ResolvedSource? failedSource,
    required Duration currentPosition,
    required void Function(ResolvedSource source, Duration startAt)
        onSourceReady,
    bool isPlaybackStall = false,
  }) async {
    if (_disposed) return;
    final sessionId = _currentSessionId;

    final currentServerIdx = state.selectedServerIndex;
    final currentServer = state.selectedServer;
    if (currentServer == null || currentServerIdx == null) return;

    // Guard against obsolete callbacks:
    // If a specific failedSource is provided and it doesn't match the active playback,
    // verify whether it belongs to current session. If it's a stale player callback, discard.
    int targetSourceIdx = -1;
    if (failedSource != null) {
      targetSourceIdx = currentServer.sources.indexWhere(
        (s) => s.id == failedSource.id && s.url == failedSource.url,
      );
      if (targetSourceIdx == -1 && state.currentSource != null) {
        if (failedSource.id != state.currentSource!.id &&
            failedSource.url != state.currentSource!.url) {
          debugPrint(
              'StreamResolutionNotifier: Discarding obsolete failure event for source ${failedSource.displayName}');
          return;
        }
      }
    }
    if (targetSourceIdx == -1) {
      targetSourceIdx = state.selectedSourceIndex ?? 0;
    }

    final currentAttempts = state.fallbackAttempts + 1;
    const maxFallbackAttempts = 5;

    debugPrint(
        'StreamResolution: TMDB=${state.context?.tmdbId}, Server=${currentServer.name}, SourceIndex=$targetSourceIdx, Attempts=$currentAttempts, FailureCategory=${isPlaybackStall ? "playback_stall" : "playback_error"}');

    if (currentAttempts > maxFallbackAttempts) {
      state = state.copyWith(
        fallbackAttempts: currentAttempts,
        errorMessage: isPlaybackStall
            ? 'Playback stalled, try again'
            : 'No playable sources found',
      );
      return;
    }

    // 1. Check if current server has another untried valid source link
    final updatedSources = List<ResolvedSource>.from(currentServer.sources);
    if (targetSourceIdx >= 0 && targetSourceIdx < updatedSources.length) {
      updatedSources[targetSourceIdx] =
          updatedSources[targetSourceIdx].copyWith(isFailed: true);
    }

    final nextUntriedSourceIdx = updatedSources.indexWhere(
      (s) => !s.isFailed && s.isValidUrl,
    );

    if (nextUntriedSourceIdx != -1) {
      final nextSource = updatedSources[nextUntriedSourceIdx];
      _updateServerSources(currentServerIdx, updatedSources,
          ServerResolutionStatus.ready, sessionId);

      state = state.copyWith(
        selectedSourceIndex: nextUntriedSourceIdx,
        currentSource: nextSource,
        fallbackAttempts: currentAttempts,
        statusMessage: 'Source failed. Trying ${nextSource.displayName}...',
      );

      onSourceReady(nextSource, currentPosition);
      return;
    } else {
      // Current server's links are exhausted
      _updateServerSources(currentServerIdx, updatedSources,
          ServerResolutionStatus.failed, sessionId);
      _updateServerStatus(
        currentServerIdx,
        ServerResolutionStatus.failed,
        errorMessage: 'All links failed',
        sessionId: sessionId,
      );
    }

    // 2. Try another server with resolved sources (Ready)
    final otherReadyIdx = state.servers.indexWhere(
      (s) => s.isReady && s != currentServer,
    );

    if (otherReadyIdx != -1) {
      final readyServer = state.servers[otherReadyIdx];
      final candidateSource = readyServer.sources.firstWhere(
        (s) => !s.isFailed && s.isValidUrl,
      );

      state = state.copyWith(
        selectedServerIndex: otherReadyIdx,
        selectedSourceIndex: readyServer.sources.indexOf(candidateSource),
        currentSource: candidateSource,
        fallbackAttempts: currentAttempts,
        statusMessage: 'Server failed. Falling back to ${readyServer.name}...',
      );
      sourcesList = readyServer.sources.map((s) => s.toJson()).toList();

      onSourceReady(candidateSource, currentPosition);
      return;
    }

    // 3. Resolve next supported server on demand
    final context = state.context;
    if (context == null) return;

    final nextIdleIdx = state.servers.indexWhere(
      (s) =>
          s.isPlayable &&
          s.resolutionStatus == ServerResolutionStatus.idle &&
          s != currentServer,
    );

    if (nextIdleIdx != -1) {
      final nextServer = state.servers[nextIdleIdx];
      state = state.copyWith(
        fallbackAttempts: currentAttempts,
        statusMessage: 'Falling back to ${nextServer.name}...',
      );

      _updateServerStatus(nextIdleIdx, ServerResolutionStatus.loading,
          sessionId: sessionId);

      try {
        final sources =
            await _repository.getSources(context, nextServer.scraper);
        if (_disposed || _currentSessionId != sessionId) return;

        if (sources.isNotEmpty && sources.any((s) => s.isValidUrl)) {
          final prioritizedSources = _sortSourcesByLanguage(sources);
          _updateServerSources(
              nextIdleIdx, prioritizedSources, ServerResolutionStatus.ready, sessionId);
          sourcesList = prioritizedSources.map((s) => s.toJson()).toList();

          final chosen = prioritizedSources.firstWhere((s) => s.isValidUrl);

          state = state.copyWith(
            selectedServerIndex: nextIdleIdx,
            selectedSourceIndex: prioritizedSources.indexOf(chosen),
            currentSource: chosen,
            statusMessage: 'Switched to fallback server ${nextServer.name}',
          );

          onSourceReady(chosen, currentPosition);
          return;
        } else {
          _updateServerStatus(nextIdleIdx, ServerResolutionStatus.failed,
              errorMessage: 'No links', sessionId: sessionId);
          return await handleSourceFailure(
            currentPosition: currentPosition,
            isPlaybackStall: isPlaybackStall,
            onSourceReady: onSourceReady,
          );
        }
      } catch (e) {
        if (_disposed || _currentSessionId != sessionId) return;
        _updateServerStatus(nextIdleIdx, ServerResolutionStatus.failed,
            errorMessage: e.toString(), sessionId: sessionId);
        return await handleSourceFailure(
          currentPosition: currentPosition,
          isPlaybackStall: isPlaybackStall,
          onSourceReady: onSourceReady,
        );
      }
    }

    // 4. Exhausted
    state = state.copyWith(
      fallbackAttempts: currentAttempts,
      errorMessage: isPlaybackStall
          ? 'Playback stalled, try again'
          : 'No playable sources found',
    );
  }

  void _updateServerStatus(
    int index,
    ServerResolutionStatus status, {
    String? errorMessage,
    int? sessionId,
  }) {
    if (_disposed) return;
    if (sessionId != null && sessionId != _currentSessionId) return;
    if (index < 0 || index >= state.servers.length) return;
    final updatedList = List<ServerItem>.from(state.servers);
    updatedList[index] = updatedList[index].copyWith(
      resolutionStatus: status,
      errorMessage: errorMessage,
    );
    state = state.copyWith(servers: updatedList);
  }

  void _updateServerSources(
    int index,
    List<ResolvedSource> sources,
    ServerResolutionStatus status,
    int? sessionId,
  ) {
    if (_disposed) return;
    if (sessionId != null && sessionId != _currentSessionId) return;
    if (index < 0 || index >= state.servers.length) return;
    final updatedList = List<ServerItem>.from(state.servers);
    updatedList[index] = updatedList[index].copyWith(
      sources: sources,
      resolutionStatus: status,
    );
    state = state.copyWith(servers: updatedList);
  }
}

final streamResolutionControllerProvider = NotifierProvider<
    StreamResolutionNotifier, StreamResolutionState>(() {
  return StreamResolutionNotifier();
});
