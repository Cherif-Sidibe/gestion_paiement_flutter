import 'package:flutter/foundation.dart';

import 'package:gestion_paiement_flutter/core/network/api_exception.dart';
import 'package:gestion_paiement_flutter/core/network/wallet_api_service.dart';
import 'package:gestion_paiement_flutter/core/state/view_state.dart';
import 'package:gestion_paiement_flutter/core/storage/session_storage.dart';
import 'package:gestion_paiement_flutter/models/wallet_model.dart';

/// Gere la session : connexion par numero de telephone et persistance securisee.
class AuthProvider extends ChangeNotifier {
  final WalletApiService _walletApiService;
  final SessionStorage _sessionStorage;

  AuthProvider(this._walletApiService, this._sessionStorage);

  ViewState _state = ViewState.initial;
  Wallet? _wallet;
  String? _phone;
  String? _errorMessage;

  ViewState get state => _state;
  Wallet? get wallet => _wallet;
  String? get phone => _phone;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _wallet != null;

  /// Restaure une eventuelle session sauvegardee au demarrage.
  Future<void> restoreSession() async {
    _phone = await _sessionStorage.readPhone();
    notifyListeners();
  }

  /// Verifie le numero contre le back puis sauvegarde la session si valide.
  Future<bool> login(String phone) async {
    _state = ViewState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _wallet = await _walletApiService.getWallet(phone);
      _phone = phone;
      await _sessionStorage.savePhone(phone);
      _state = ViewState.loaded;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = ViewState.error;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Une erreur inattendue est survenue.';
      _state = ViewState.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _sessionStorage.clear();
    _wallet = null;
    _phone = null;
    _state = ViewState.initial;
    notifyListeners();
  }
}
