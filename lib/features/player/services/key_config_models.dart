/// Immutable snapshot of the remote encryption key configuration.
class KeyConfig {
  final int version;
  final String key;
  final int lastCheckedTimestamp;

  const KeyConfig({
    required this.version,
    required this.key,
    required this.lastCheckedTimestamp,
  });

  /// Validates whether the configuration snapshot is complete and non-empty.
  bool get isValid => key.trim().isNotEmpty && version > 0;

  KeyConfig copyWith({
    int? version,
    String? key,
    int? lastCheckedTimestamp,
  }) {
    return KeyConfig(
      version: version ?? this.version,
      key: key ?? this.key,
      lastCheckedTimestamp: lastCheckedTimestamp ?? this.lastCheckedTimestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'version': version,
      'key': key,
      'last_checked_timestamp': lastCheckedTimestamp,
    };
  }

  factory KeyConfig.fromMap(Map map) {
    final rawVersion = map['version'];
    final int parsedVersion;
    if (rawVersion is int) {
      parsedVersion = rawVersion;
    } else if (rawVersion is num) {
      parsedVersion = rawVersion.toInt();
    } else if (rawVersion is String) {
      parsedVersion = int.tryParse(rawVersion) ?? 0;
    } else {
      parsedVersion = 0;
    }

    final rawLastChecked = map['last_checked_timestamp'];
    final int parsedLastChecked;
    if (rawLastChecked is int) {
      parsedLastChecked = rawLastChecked;
    } else if (rawLastChecked is num) {
      parsedLastChecked = rawLastChecked.toInt();
    } else if (rawLastChecked is String) {
      parsedLastChecked = int.tryParse(rawLastChecked) ?? 0;
    } else {
      parsedLastChecked = 0;
    }

    return KeyConfig(
      version: parsedVersion,
      key: map['key']?.toString().trim() ?? '',
      lastCheckedTimestamp: parsedLastChecked,
    );
  }

  @override
  String toString() =>
      'KeyConfig(version: $version, keyLen: ${key.length}, lastChecked: $lastCheckedTimestamp)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KeyConfig &&
          runtimeType == other.runtimeType &&
          version == other.version &&
          key == other.key &&
          lastCheckedTimestamp == other.lastCheckedTimestamp;

  @override
  int get hashCode => Object.hash(version, key, lastCheckedTimestamp);
}

/// Result status of a key refresh or version check request.
enum KeyRefreshResult {
  /// A newer version or different valid key was downloaded and activated.
  updated,

  /// The local configuration is already up to date with the remote configuration.
  noChange,

  /// The request or validation failed; previous working configuration was retained.
  failed,
}

/// Thrown when the cryptographic decoding algorithm fails to decrypt or decode a response.
class CryptoDecodingException implements Exception {
  final String message;
  final Object? cause;

  const CryptoDecodingException(this.message, [this.cause]);

  @override
  String toString() => 'CryptoDecodingException: $message';
}

/// Thrown when an encryption/decryption key is required but missing or unconfigured.
class KeyConfigException implements Exception {
  final String message;
  final Object? cause;

  const KeyConfigException(this.message, [this.cause]);

  @override
  String toString() => 'KeyConfigException: $message';
}
