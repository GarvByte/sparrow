/// Normalized audio language supported by the player.
enum SourceLanguage {
  hindi,
  english,
  multi,
  unsupported,
  unknown,
}

/// Represents a resolved streaming source URL returned from a provider.
class ResolvedSource {
  final String id;
  final String provider;
  final String url;
  final String? quality;
  final String? label;
  final Map<String, String> headers;
  final String? type;
  final bool isEmbed;
  final bool isFailed;
  final SourceLanguage language;

  const ResolvedSource({
    required this.id,
    required this.provider,
    required this.url,
    this.quality,
    this.label,
    this.headers = const {},
    this.type,
    this.isEmbed = false,
    this.isFailed = false,
    this.language = SourceLanguage.unknown,
  });

  /// Normalizes and detects audio language from source metadata.
  static SourceLanguage detectLanguage(
    String? label,
    String? quality, {
    String? provider,
  }) {
    final text = '${label ?? ''} ${quality ?? ''}'.toLowerCase();

    final hindiRegex = RegExp(
      r'\b(hindi|hin|hi)\b|\[hindi\]|\(hindi\)|हिन्दी|dual\s*audio',
    );
    final englishRegex = RegExp(
      r'\b(english|eng|en)\b|\[english\]|\(english\)|\[ost\]|\(ost\)',
    );
    final unsupportedRegex = RegExp(
      r'\b(tamil|tam|ta|telugu|tel|te|bengali|ben|bn|malayalam|mal|ml|kannada|kan|kn|marathi|mar|mr|punjabi|pan|pa|gujarati|guj|gu|vietsub|thuyết minh|viet|spanish|español|french|français|german|deutsch|italian|italiano|russian|русский|portuguese|português)\b|\[tamil\]|\[telugu\]|\[bengali\]',
    );

    final hasHindi = hindiRegex.hasMatch(text);
    final hasEnglish = englishRegex.hasMatch(text);
    final hasUnsupported = unsupportedRegex.hasMatch(text);

    if (hasHindi && hasEnglish) {
      return SourceLanguage.multi;
    }
    if (hasHindi && !hasUnsupported) {
      return SourceLanguage.hindi;
    }
    if (hasEnglish && !hasUnsupported) {
      return SourceLanguage.english;
    }
    if (hasUnsupported && !hasHindi && !hasEnglish) {
      return SourceLanguage.unsupported;
    }
    if (hasHindi) {
      return SourceLanguage.hindi;
    }
    if (hasEnglish) {
      return SourceLanguage.english;
    }
    if (hasUnsupported) {
      return SourceLanguage.unsupported;
    }

    // Provider-specific metadata hints when label does not contain language tags
    if (provider != null) {
      final p = provider.toLowerCase().trim();
      if (p == 'nitro' || p == 'watchout') {
        return SourceLanguage.multi;
      }
      if (p == 'vidhindi' || p == 'em-8') {
        return SourceLanguage.hindi;
      }
    }

    return SourceLanguage.unknown;
  }

  factory ResolvedSource.fromJson(
    Map<String, dynamic> json, {
    String? defaultProvider,
  }) {
    final rawHeaders = json['headers'];
    final Map<String, String> parsedHeaders = {
      'Referer': 'https://nxsha.space/',
    };
    if (rawHeaders is Map) {
      rawHeaders.forEach((key, value) {
        if (value != null) {
          parsedHeaders[key.toString()] = value.toString();
        }
      });
    }

    final p = (json['provider'] ?? defaultProvider ?? 'unknown').toString();
    final l = json['label']?.toString();
    final q = json['quality']?.toString();

    SourceLanguage parsedLang;
    if (json['language'] != null) {
      try {
        parsedLang = SourceLanguage.values.byName(json['language'].toString());
      } catch (_) {
        parsedLang = detectLanguage(l, q, provider: p);
      }
    } else {
      parsedLang = detectLanguage(l, q, provider: p);
    }

    return ResolvedSource(
      id: (json['id'] ?? json['scraper'] ?? '').toString(),
      provider: p,
      url: (json['url'] ?? json['file'] ?? '').toString().trim(),
      quality: q,
      label: l,
      headers: parsedHeaders,
      type: json['type']?.toString(),
      isEmbed: json['isEmbed'] as bool? ?? false,
      isFailed: json['isFailed'] as bool? ?? false,
      language: parsedLang,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider': provider,
      'url': url,
      'quality': quality,
      'label': label,
      'headers': headers,
      'type': type,
      'isEmbed': isEmbed,
      'isFailed': isFailed,
      'language': language.name,
    };
  }

  ResolvedSource copyWith({
    String? id,
    String? provider,
    String? url,
    String? quality,
    String? label,
    Map<String, String>? headers,
    String? type,
    bool? isEmbed,
    bool? isFailed,
    SourceLanguage? language,
  }) {
    return ResolvedSource(
      id: id ?? this.id,
      provider: provider ?? this.provider,
      url: url ?? this.url,
      quality: quality ?? this.quality,
      label: label ?? this.label,
      headers: headers ?? this.headers,
      type: type ?? this.type,
      isEmbed: isEmbed ?? this.isEmbed,
      isFailed: isFailed ?? this.isFailed,
      language: language ?? this.language,
    );
  }

  /// Whether this source satisfies the language policy (Hindi or English).
  bool get isSupportedLanguage =>
      language == SourceLanguage.hindi ||
      language == SourceLanguage.english ||
      language == SourceLanguage.multi;

  /// Whether Hindi is present or preferred in this source.
  bool get isHindiPreferred =>
      language == SourceLanguage.hindi || language == SourceLanguage.multi;

  /// Short user-facing language chip label.
  String get languageBadge {
    switch (language) {
      case SourceLanguage.hindi:
        return 'Hindi';
      case SourceLanguage.english:
        return 'English';
      case SourceLanguage.multi:
        return 'Hindi • English';
      case SourceLanguage.unsupported:
        return 'Other';
      case SourceLanguage.unknown:
        return 'English';
    }
  }

  /// User-facing display title for link selection.
  String get displayName {
    if (label != null && label!.trim().isNotEmpty) {
      return label!;
    }
    if (quality != null && quality!.trim().isNotEmpty) {
      return quality!;
    }
    if (id.isNotEmpty) {
      return 'Link $id';
    }
    return 'Stream Link';
  }

  bool get isValidUrl =>
      url.isNotEmpty &&
      (url.startsWith('http://') || url.startsWith('https://'));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResolvedSource &&
          runtimeType == other.runtimeType &&
          url == other.url &&
          provider == other.provider;

  @override
  int get hashCode => Object.hash(url, provider);

  @override
  String toString() =>
      'ResolvedSource(id: $id, provider: $provider, url: $url, lang: ${language.name})';
}
