import 'package:flutter/foundation.dart';

import 'package:gestion_paiement_flutter/core/network/api_exception.dart';
import 'package:gestion_paiement_flutter/core/network/wallet_api_service.dart';
import 'package:gestion_paiement_flutter/core/state/view_state.dart';

/// Gere l'envoi d'un transfert (pattern Loading/Loaded/Error).
///
/// Avant l'envoi, [verifierDestinataire] confirme que le numero cible existe
/// (GET /{phone}) pour un meilleur feedback. L'envoi lui-meme passe par
/// [WalletApiService.transfer] ; un solde insuffisant ou une autre erreur
/// metier remonte le message FR du back via [ApiException].
class TransferProvider extends ChangeNotifier {
  final WalletApiService _walletApiService;

  TransferProvider(this._walletApiService);

  ViewState _state = ViewState.initial;
  String? _errorMessage;

  ViewState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == ViewState.loading;

  /// Verifie l'existence du destinataire. Renvoie `true` s'il existe, `false`
  /// avec un message FR sinon (404 -> "Le destinataire n'existe pas").
  Future<bool> verifierDestinataire(String receiverPhone) async {
    _state = ViewState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _walletApiService.getWallet(receiverPhone);
      _state = ViewState.loaded;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage =
          e.statusCode == 404 ? "Le destinataire n'existe pas." : e.message;
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

  /// Envoie le transfert. Renvoie `true` en cas de succes, `false` avec un
  /// message metier FR ([errorMessage]) sinon.
  Future<bool> envoyer({
    required String senderPhone,
    required String receiverPhone,
    required double amount,
  }) async {
    _state = ViewState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _walletApiService.transfer(
        senderPhone: senderPhone,
        receiverPhone: receiverPhone,
        amount: amount,
      );
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
}
