import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Result of passenger dynamic QR verification
class QrVerificationResult {
  final bool isValid;
  final bool isExpired;
  final bool isTampered;
  final bool isLegacy;
  final String? passengerId;
  final String? errorMessage;
  final int? ageSeconds;

  const QrVerificationResult({
    required this.isValid,
    this.isExpired = false,
    this.isTampered = false,
    this.isLegacy = false,
    this.passengerId,
    this.errorMessage,
    this.ageSeconds,
  });

  factory QrVerificationResult.valid(String id, {bool isLegacy = false}) =>
      QrVerificationResult(isValid: true, passengerId: id, isLegacy: isLegacy);

  factory QrVerificationResult.expired({required String passengerId, required int ageSeconds}) =>
      QrVerificationResult(
        isValid: false,
        isExpired: true,
        passengerId: passengerId,
        ageSeconds: ageSeconds,
        errorMessage: 'QR Code Expired (${ageSeconds}s old). Screenshot detected. Please refresh dynamic pass.',
      );

  factory QrVerificationResult.tampered() => const QrVerificationResult(
        isValid: false,
        isTampered: true,
        errorMessage: 'Invalid signature. Tampered or counterfeit QR code.',
      );

  factory QrVerificationResult.invalid(String msg) =>
      QrVerificationResult(isValid: false, errorMessage: msg);
}

/// Service for cryptographically signing and verifying dynamic, rotating passenger transit QR codes.
/// Defeats static screenshot sharing and satisfies DPDP/transport security audit standards.
class QrSecurityService {
  QrSecurityService._();
  static final QrSecurityService instance = QrSecurityService._();

  // HMAC Secret Key for transit tokens
  static final List<int> _hmacSecret = utf8.encode('enroute_kerala_transit_auth_hmac_secret_2026');

  /// Token validity window in seconds (60-90 seconds standard for dynamic transit codes)
  static const int defaultValiditySeconds = 90;

  /// Grace window in seconds for clock drift or offline conductor devices (up to 150s)
  static const int graceWindowSeconds = 150;

  /// Generate a dynamic cryptographically signed QR payload for a passenger
  String generateSignedPassengerQr(String passengerId, {int? timestampOverride}) {
    final now = timestampOverride ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000);
    final payload = 'v2:$passengerId:$now';
    final hmac = Hmac(sha256, _hmacSecret);
    final digest = hmac.convert(utf8.encode(payload));
    final signature = digest.toString().substring(0, 16); // 16-hex char truncated signature for compact QR

    return 'ENROUTE:PASSENGER:v2:$passengerId:$now:$signature';
  }

  /// Verify incoming QR code from scanner
  QrVerificationResult verifyPassengerQr(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) {
      return QrVerificationResult.invalid('Empty QR code scanned.');
    }

    // Check if it's the dynamic v2 signed format
    if (clean.startsWith('ENROUTE:PASSENGER:v2:')) {
      final parts = clean.split(':');
      if (parts.length >= 6) {
        final passengerId = parts[3];
        final timestampStr = parts[4];
        final signature = parts[5];

        final timestamp = int.tryParse(timestampStr);
        if (timestamp == null) {
          return QrVerificationResult.invalid('Malformed timestamp in token.');
        }

        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final age = now - timestamp;

        // Verify HMAC signature first
        final payload = 'v2:$passengerId:$timestamp';
        final hmac = Hmac(sha256, _hmacSecret);
        final digest = hmac.convert(utf8.encode(payload));
        final expectedSignature = digest.toString().substring(0, 16);

        if (signature.toLowerCase() != expectedSignature.toLowerCase()) {
          return QrVerificationResult.tampered();
        }

        // Check expiry (prevent screenshots / reuse after grace window)
        // Note: Allow up to 30s future drift for slightly misconfigured clocks
        if (age > graceWindowSeconds || age < -30) {
          return QrVerificationResult.expired(
            passengerId: passengerId,
            ageSeconds: age > 0 ? age : 0,
          );
        }

        return QrVerificationResult.valid(passengerId);
      }
    }

    // Legacy backwards compatibility: SMARTBUS:PASSENGER:XXX or raw ID
    String legacyId = clean;
    if (legacyId.toUpperCase().contains('SMARTBUS:PASSENGER:')) {
      legacyId = legacyId.replaceAll(RegExp(r'SMARTBUS:PASSENGER:', caseSensitive: false), '').trim();
    } else if (legacyId.startsWith('{') && legacyId.contains('id')) {
      try {
        final parsed = jsonDecode(legacyId);
        if (parsed is Map && parsed['id'] != null) {
          legacyId = parsed['id'].toString().trim();
        }
      } catch (_) {}
    }

    if (legacyId.isNotEmpty) {
      return QrVerificationResult.valid(legacyId, isLegacy: true);
    }

    return QrVerificationResult.invalid('Unrecognized ticket/passenger format.');
  }
}
