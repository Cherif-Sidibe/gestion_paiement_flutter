import 'package:flutter/foundation.dart';

import 'package:gestion_paiement_flutter/core/network/api_exception.dart';
import 'package:gestion_paiement_flutter/core/network/wallet_api_service.dart';
import 'package:gestion_paiement_flutter/core/state/view_state.dart';
import 'package:gestion_paiement_flutter/models/transaction_model.dart';

/// Charge et expose l'historique des transactions de la wallet courante
/// (pattern Loading/Loaded/Error). Le back renvoie du plus recent au plus ancien.
class TransactionsProvider extends ChangeNotifier {
  final WalletApiService _walletApiService;

  TransactionsProvider(this._walletApiService);

  ViewState _state = ViewState.initial;
  List<Transaction> _transactions = const [];
  String? _errorMessage;
  String? _phone;

  ViewState get state => _state;
  List<Transaction> get transactions => _transactions;
  String? get errorMessage => _errorMessage;

  /// Les 5 transactions les plus recentes (apercu du dashboard).
  List<Transaction> get latest => _transactions.take(5).toList();

  /// Toute la liste (recent -> ancien) pour l'ecran historique.
  List<Transaction> get all => _transactions;

  Future<void> loadTransactions(String phone) async {
    _phone = phone;
    _state = ViewState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _transactions = await _walletApiService.getTransactions(phone);
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

  /// Recharge l'historique du dernier numero connu (au retour sur le dashboard).
  Future<void> refresh() async {
    final phone = _phone;
    if (phone == null) return;
    await loadTransactions(phone);
  }
}
