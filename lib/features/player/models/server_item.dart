import 'resolved_source.dart';

enum ServerResolutionStatus {
  idle,
  loading,
  ready,
  failed,
}

/// Represents a streaming server/scraper from the decoded server list.
class ServerItem {
  final dynamic id;
  final String name;
  final String scraper;
  final bool webSupport;
  final String? quality;
  final String? status;
  final List<String> types;
  final String? country;
  final String? flagImg;
  final bool isDisable;
  final ServerResolutionStatus resolutionStatus;
  final List<ResolvedSource> sources;
  final String? errorMessage;

  const ServerItem({
    required this.id,
    required this.name,
    required this.scraper,
    this.webSupport = true,
    this.quality,
    this.status,
    this.types = const [],
    this.country,
    this.flagImg,
    this.isDisable = false,
    this.resolutionStatus = ServerResolutionStatus.idle,
    this.sources = const [],
    this.errorMessage,
  });

  /// Parse from raw API JSON.
  /// Note: Only skips web_support when explicitly false.
  factory ServerItem.fromJson(Map<String, dynamic> json) {
    List<String> parsedTypes = [];
    if (json['types'] is List) {
      parsedTypes = (json['types'] as List).map((e) => e.toString()).toList();
    }

    final rawWebSupport = json['web_support'];
    final bool webSupport = rawWebSupport != false;

    return ServerItem(
      id: json['id'] ?? json['scraper'] ?? '',
      name: (json['name'] ?? json['scraper'] ?? 'Unknown Server').toString(),
      scraper: (json['scraper'] ?? '').toString().trim(),
      webSupport: webSupport,
      quality: json['quality']?.toString(),
      status: json['status']?.toString(),
      types: parsedTypes,
      country: json['country']?.toString(),
      flagImg: json['flagImg']?.toString(),
      isDisable: json['isDisable'] as bool? ?? false,
      resolutionStatus: ServerResolutionStatus.idle,
      sources: const [],
      errorMessage: null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'scraper': scraper,
      'web_support': webSupport,
      'quality': quality,
      'status': status,
      'types': types,
      'country': country,
      'flagImg': flagImg,
      'isDisable': isDisable,
    };
  }

  ServerItem copyWith({
    dynamic id,
    String? name,
    String? scraper,
    bool? webSupport,
    String? quality,
    String? status,
    List<String>? types,
    String? country,
    String? flagImg,
    bool? isDisable,
    ServerResolutionStatus? resolutionStatus,
    List<ResolvedSource>? sources,
    String? errorMessage,
  }) {
    return ServerItem(
      id: id ?? this.id,
      name: name ?? this.name,
      scraper: scraper ?? this.scraper,
      webSupport: webSupport ?? this.webSupport,
      quality: quality ?? this.quality,
      status: status ?? this.status,
      types: types ?? this.types,
      country: country ?? this.country,
      flagImg: flagImg ?? this.flagImg,
      isDisable: isDisable ?? this.isDisable,
      resolutionStatus: resolutionStatus ?? this.resolutionStatus,
      sources: sources ?? this.sources,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Whether this server is playable and supported.
  bool get isPlayable => webSupport && !isDisable && scraper.isNotEmpty;

  /// Whether this server has resolved at least one playable candidate source.
  bool get isReady =>
      resolutionStatus == ServerResolutionStatus.ready &&
      sources.any((s) => !s.isFailed && s.isValidUrl);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServerItem &&
          runtimeType == other.runtimeType &&
          scraper == other.scraper;

  @override
  int get hashCode => scraper.hashCode;

  @override
  String toString() =>
      'ServerItem(name: $name, scraper: $scraper, status: $resolutionStatus, sources: ${sources.length})';
}
