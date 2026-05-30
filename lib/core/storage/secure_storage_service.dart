import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  static const _keyFirebaseUid = 'firebase_uid';
  static const _keyFullName = 'full_name';
  static const _keyEmail = 'email';
  static const _keyPinHash = 'pin_hash';
  static const _keyPinSalt = 'pin_salt';

  static const _keyPendingFullName = 'pending_full_name';
  static const _keyPendingEmail = 'pending_email';

  Future<void> saveUser({
    required String firebaseUid,
    required String fullName,
    required String email,
  }) async {
    await _storage.write(key: _keyFirebaseUid, value: firebaseUid);
    await _storage.write(key: _keyFullName, value: fullName);
    await _storage.write(key: _keyEmail, value: email);
  }

  Future<void> savePin({
    required String pinHash,
    required String pinSalt,
  }) async {
    await _storage.write(key: _keyPinHash, value: pinHash);
    await _storage.write(key: _keyPinSalt, value: pinSalt);
  }

  Future<String?> getFirebaseUid() async {
    return _storage.read(key: _keyFirebaseUid);
  }

  Future<String?> getFullName() async {
    return _storage.read(key: _keyFullName);
  }

  Future<String?> getEmail() async {
    return _storage.read(key: _keyEmail);
  }

  Future<String?> getPinHash() async {
    return _storage.read(key: _keyPinHash);
  }

  Future<String?> getPinSalt() async {
    return _storage.read(key: _keyPinSalt);
  }

  Future<bool> hasPinEnrolled() async {
    final pinHash = await getPinHash();
    final pinSalt = await getPinSalt();

    return pinHash != null &&
        pinHash.isNotEmpty &&
        pinSalt != null &&
        pinSalt.isNotEmpty;
  }

  Future<void> savePendingRegistration({
    required String fullName,
    required String email,
  }) async {
    await _storage.write(
      key: _keyPendingFullName,
      value: fullName.trim(),
    );

    await _storage.write(
      key: _keyPendingEmail,
      value: email.trim().toLowerCase(),
    );
  }

  Future<String?> getPendingFullName() async {
    return _storage.read(key: _keyPendingFullName);
  }

  Future<String?> getPendingEmail() async {
    return _storage.read(key: _keyPendingEmail);
  }

  Future<void> clearPendingRegistration() async {
    await _storage.delete(key: _keyPendingFullName);
    await _storage.delete(key: _keyPendingEmail);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}