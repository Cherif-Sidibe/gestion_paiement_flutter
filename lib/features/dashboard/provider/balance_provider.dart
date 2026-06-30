import 'package:flutter/foundation.dart';

import 'package:gestion_paiement_flutter/core/network/api_exception.dart';
import 'package:gestion_paiement_flutter/core/network/wallet_api_service.dart';
import 'package:gestion_paiement_flutter/core/state/view_state.dart';
import 'package:gestion_paiement_flutter/models/wallet_model.dart';

/// Charge et expose le solde de la wallet courante (pattern Loading/Loaded/Error).
class BalanceProvider extends ChangeNotifier {
  final WalletApiService _walletApiService;

  BalanceProvider(this._walletApiService);

  ViewState _state = ViewState.initial;
  WalletBalance? _balance;
  String? _errorMessage;
  String? _phone;

  ViewState get state => _state;
  WalletBalance? get balance => _balance;
  String? get errorMessage => _errorMessage;

  Future<void> loadBalance(String phone) async {
    _phone = phone;
    _state = ViewState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _balance = await _walletApiService.getBalance(phone);
      _state = ViewState.loaded;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = ViewState.error;
    } catch (_) {
      _errorMessage = 'Une erreur inattendue est survenue.';
      _state = ViewState.error;
    }
    notifyListeners();
  }

  /// Recharge le solde du dernier numero connu (apres une operation, au retour
  /// sur le dashboard). Sans numero memorise, ne fait rien.
  Future<void> refresh() async {
    final phone = _phone;
    if (phone == null) return;
    await loadBalance(phone);
  }
}
