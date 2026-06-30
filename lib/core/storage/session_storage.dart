import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persistance securisee de la session (numero de telephone de l'utilisateur).
class SessionStorage {
  static const _phoneKey = 'session_phone';

  final FlutterSecureStorage _storage;

  SessionStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> savePhone(String phone) => _storage.write(key: _phoneKey, value: phone);

  Future<String?> readPhone() => _storage.read(key: _phoneKey);

  Future<void> clear() => _storage.delete(key: _phoneKey);
}
