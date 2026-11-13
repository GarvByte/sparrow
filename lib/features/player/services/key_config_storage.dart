import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'key_config_models.dart';

/// Hive-backed persistent storage manager for remote encryption key configuration.
class KeyConfigStorage {
  static const String boxName = 'sparrow_key_config_box';
  static const String _keyKey = 'encryption_key';
  static const String _versionKey = 'config_version';
  static const String _lastCheckedKey = 'last_checked_timestamp';

  static bool _initialized = false;

  /// Initializes the Hive key configuration box safely.
  static Future<void> init() async {
    if (_initialized) return;
    try {
      if (!Hive.isBoxOpen(boxName)) {
        await Hive.openBox(boxName);
      }
      _initialized = true;
    } catch (e, stack) {
      debugPrint('KeyConfigStorage.init error: $e\n$stack');
    }
  }

  static Future<Box?> _openBox() async {
    try {
      if (Hive.isBoxOpen(boxName)) {
        return Hive.box(boxName);
      }
      return await Hive.openBox(boxName);
    } catch (e) {
      debugPrint('KeyConfigStorage._openBox error: $e');
      return null;
    }
  }

  /// Loads the persisted configuration snapshot from Hive if valid.
  static Future<KeyConfig?> loadConfig() async {
    try {
      final box = await _openBox();
      if (box == null) return null;

      final key = box.get(_keyKey) as String?;
      final version = box.get(_versionKey);
      final lastChecked = box.get(_lastCheckedKey);

      if (key == null || key.trim().isEmpty) {
        return null;
      }

      final int parsedVersion;
      if (version is int) {
        parsedVersion = version;
      } else if (version is num) {
        parsedVersion = version.toInt();
      } else if (version is String) {
        parsedVersion = int.tryParse(version) ?? 0;
      } else {
        parsedVersion = 0;
      }

      if (parsedVersion <= 0) return null;

      final int parsedLastChecked;
      if (lastChecked is int) {
        parsedLastChecked = lastChecked;
      } else if (lastChecked is num) {
        parsedLastChecked = lastChecked.toInt();
      } else if (lastChecked is String) {
        parsedLastChecked = int.tryParse(lastChecked) ?? 0;
      } else {
        parsedLastChecked = 0;
      }

      final config = KeyConfig(
        version: parsedVersion,
        key: key.trim(),
        lastCheckedTimestamp: parsedLastChecked,
      );

      return config.isValid ? config : null;
    } catch (e) {
      debugPrint('KeyConfigStorage.loadConfig error: $e');
      return null;
    }
  }

  /// Persists a validated configuration snapshot atomically.
  /// Never overwrites valid configuration with an invalid one.
  static Future<bool> saveConfig(KeyConfig config) async {
    if (!config.isValid) {
      debugPrint('KeyConfigStorage.saveConfig: Refusing to save invalid config');
      return false;
    }

    try {
      final box = await _openBox();
      if (box == null) return false;

      await box.putAll({
        _keyKey: config.key.trim(),
        _versionKey: config.version,
        _lastCheckedKey: config.lastCheckedTimestamp,
      });
      return true;
    } catch (e) {
      debugPrint('KeyConfigStorage.saveConfig error: $e');
      return false;
    }
  }

  /// Updates only the last successful check timestamp in Hive.
  static Future<void> updateLastChecked(int timestamp) async {
    try {
      final box = await _openBox();
      if (box == null) return;
      await box.put(_lastCheckedKey, timestamp);
    } catch (e) {
      debugPrint('KeyConfigStorage.updateLastChecked error: $e');
    }
  }

  /// Clears stored key configuration (used primarily in test suites).
  static Future<void> clear() async {
    try {
      final box = await _openBox();
      if (box != null) {
        await box.clear();
      }
    } catch (e) {
      debugPrint('KeyConfigStorage.clear error: $e');
    }
  }
}
