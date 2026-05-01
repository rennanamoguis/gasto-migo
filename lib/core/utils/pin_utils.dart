import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class PinUtils {
  static bool isValidPin(String pin) {
    return RegExp(r'^\d{6}$').hasMatch(pin);
  }

  static String generateSalt() {
    final random = Random.secure();
    final values = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(values);
  }

  static String hashPin({
    required String pin,
    required String salt,
  }) {
    final bytes = utf8.encode('$salt:$pin');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static bool verifyPin({
    required String enteredPin,
    required String savedHash,
    required String savedSalt,
  }) {
    final enteredHash = hashPin(
      pin: enteredPin,
      salt: savedSalt,
    );

    return enteredHash == savedHash;
  }
}