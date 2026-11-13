/// Centralized API configuration constants for Sparrow.
class ApiConfig {
  /// Base URL for the Sparrow backend proxy infrastructure.
  static const String backendBaseUrl =
      'https://sparrow-tmdb-proxy.piratesparrow.workers.dev';

  /// Path for the remote encryption key rotation configuration endpoint.
  static const String keyConfigEndpointPath = '/key';

  /// Hardcoded fallback key retained for backward compatibility and offline resilience.
  static const String defaultKey =
      'f4488ab4da401203d23baa129fc546153898162524635d6776826d0c867ccaa3';

  /// Initial default version.
  static const int defaultVersion = 1;
}
