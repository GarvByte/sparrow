import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

/// Faithful Dart port of CryptoJS AES parameter encoding and decoding
/// based on `nxsha_parametres_encoder.py` and `nxsha_decoded_scraper.py`.
class NxshaCipher {
  static const String keyString =
      'f4488ab4da401203d23baa129fc546153898162524635d6776826d0c867ccaa3';

  /// OpenSSL EVP_BytesToKey implementation used by CryptoJS when passing a string passphrase.
  static List<Uint8List> evpBytesToKey(
    List<int> passwordBytes,
    List<int> salt,
    int keyLen,
    int ivLen,
  ) {
    final List<int> d = [];
    List<int> dI = [];
    while (d.length < keyLen + ivLen) {
      final input = [...dI, ...passwordBytes, ...salt];
      final digest = md5.convert(input);
      dI = digest.bytes;
      d.addAll(dI);
    }
    return [
      Uint8List.fromList(d.sublist(0, keyLen)),
      Uint8List.fromList(d.sublist(keyLen, keyLen + ivLen)),
    ];
  }

  /// Builds the query payload map and encrypts it into a URL-safe Base64 string.
  ///
  /// For movies, [season] and [episode] must both be 0.
  /// For TV shows, use the actual selected season and episode numbers.
  /// [provider] is the selected server's scraper value when requesting sources.
  static String buildPayload({
    required String tmdbId,
    required String imdbId,
    required String type,
    required int season,
    required int episode,
    bool exLang = false,
    String? provider,
  }) {
    final Map<String, dynamic> data = {
      'ex_lang': exLang,
      if (provider != null && provider.trim().isNotEmpty)
        'provider': provider.trim(),
      'tmdbId': tmdbId.trim(),
      'imdb_id': imdbId.trim(),
      'type': type.trim(),
      'season': season,
      'episode': episode,
    };

    return encodeRequest(data);
  }

  /// Encrypts an arbitrary data Map into CryptoJS-compatible Base64 string.
  static String encodeRequest(Map<String, dynamic> data) {
    if (data.isEmpty) return '';

    try {
      final rnd = Random();
      const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';

      // Replicate payload structure with dynamic timestamp and random salt
      final Map<String, dynamic> payload = {
        ...data,
        '_req_ts': DateTime.now().millisecondsSinceEpoch,
        '_req_salt': String.fromCharCodes(
          Iterable.generate(
            10,
            (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
          ),
        ),
      };

      // Compact JSON stringification (matching JSON.stringify / python separators=(',', ':'))
      final jsonStr = jsonEncode(payload);
      final jsonBytes = utf8.encode(jsonStr);

      // Generate a random 8-byte salt for CryptoJS
      final salt = List<int>.generate(8, (_) => rnd.nextInt(256));

      // Derive key and IV using the string key as a passphrase
      final passphraseBytes = utf8.encode(keyString);
      final keyIv = evpBytesToKey(passphraseBytes, salt, 32, 16);
      final key = keyIv[0];
      final iv = keyIv[1];

      // Encrypt using AES-CBC with PKCS7 padding
      final encrypter = encrypt.Encrypter(
        encrypt.AES(
          encrypt.Key(key),
          mode: encrypt.AESMode.cbc,
          padding: 'PKCS7',
        ),
      );

      final encrypted = encrypter.encryptBytes(
        jsonBytes,
        iv: encrypt.IV(iv),
      );

      // CryptoJS standard format: 'Salted__' + salt + ciphertext
      final List<int> rawOutput = [
        ...utf8.encode('Salted__'),
        ...salt,
        ...encrypted.bytes,
      ];

      // Base64 encode and apply URL-safe replacements
      final b64Encoded = base64Encode(rawOutput);
      return b64Encoded
          .replaceAll('+', '-')
          .replaceAll('/', '_')
          .replaceAll('=', '');
    } catch (_) {
      return '';
    }
  }

  /// Decrypts a CryptoJS-compatible Base64 ciphertext into plain text JSON string.
  static String decryptCryptoJs(String ciphertextB64) {
    if (ciphertextB64.trim().isEmpty) {
      throw const FormatException('Ciphertext cannot be empty.');
    }

    // Restore standard base64 characters from URL-safe characters and add padding
    String b64 = ciphertextB64.replaceAll('-', '+').replaceAll('_', '/');
    while (b64.length % 4 != 0) {
      b64 += '=';
    }

    final Uint8List raw = base64Decode(b64);

    if (raw.length < 16) {
      throw const FormatException('Invalid ciphertext length.');
    }

    final prefix = utf8.decode(raw.sublist(0, 8), allowMalformed: true);
    if (!prefix.startsWith('Salted__')) {
      throw const FormatException("Invalid format: Missing 'Salted__' prefix.");
    }

    final salt = raw.sublist(8, 16);
    final ciphertext = raw.sublist(16);

    // Treat the key as a string passphrase (matching CryptoJS behavior)
    final passphraseBytes = utf8.encode(keyString);
    final keyIv = evpBytesToKey(passphraseBytes, salt, 32, 16);
    final key = keyIv[0];
    final iv = keyIv[1];

    final encrypter = encrypt.Encrypter(
      encrypt.AES(
        encrypt.Key(key),
        mode: encrypt.AESMode.cbc,
        padding: 'PKCS7',
      ),
    );

    final decryptedBytes = encrypter.decryptBytes(
      encrypt.Encrypted(ciphertext),
      iv: encrypt.IV(iv),
    );

    return utf8.decode(decryptedBytes);
  }
}
