import 'package:flutter/foundation.dart';

import 'package:gestion_paiement_flutter/core/network/api_exception.dart';
import 'package:gestion_paiement_flutter/core/network/billing_api_service.dart';
import 'package:gestion_paiement_flutter/core/network/wallet_api_service.dart';
import 'package:gestion_paiement_flutter/core/state/view_state.dart';
import 'package:gestion_paiement_flutter/models/facture_model.dart';

/// Charge les factures impayees du mois de la wallet courante et gere la
/// selection multiple + le paiement en lot (pattern Loading/Loaded/Error).
///
/// Lien telephone -> walletCode : le proxy factures attend le CODE wallet
/// (WLT-...), pas le telephone. On resout d'abord GET /{phone} -> wallet.code,
/// puis on appelle les factures avec ce code.
///
/// Contrainte back : pay-factures exige des factures du MEME service. La
/// selection peut etre mixte ; au paiement on la regroupe par service et on
/// envoie un POST /pay-factures par service.
class BillsProvider extends ChangeNotifier {
  final WalletApiService _walletApiService;
  final BillingApiService _billingApiService;

  BillsProvider(this._walletApiService, this._billingApiService);

  ViewState _state = ViewState.initial;
  List<Facture> _factures = const [];
  final Set<String> _selection = {};
  String? _unite;
  String? _errorMessage;
  String? _phone;
  bool _isPaying = false;

  ViewState get state => _state;
  List<Facture> get factures => _factures;
  String? get errorMessage => _errorMessage;
  String? get unite => _unite;
  bool get isPaying => _isPaying;

  /// Reference des factures cochees.
  Set<String> get selection => _selection;

  bool estSelectionnee(String reference) => _selection.contains(reference);

  List<Facture> get _facturesSelectionnees =>
      _factures.where((f) => _selection.contains(f.reference)).toList();

  int get nombreSelectionne => _selection.length;

  /// Somme des montants des factures cochees.
  double get totalSelectionne =>
      _facturesSelectionnees.fold(0, (somme, f) => somme + f.montant);

  /// Resout le walletCode depuis le telephone puis charge les factures impayees
  /// du mois, filtrees par [_unite] le cas echeant.
  Future<void> load(String phone) async {
    _phone = phone;
    _state = ViewState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final wallet = await _walletApiService.getWallet(phone);
      _factures =
          await _billingApiService.getCurrentUnpaid(wallet.code, unite: _unite);
      _selection.removeWhere(
        (ref) => !_factures.any((f) => f.reference == ref),
      );
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

  /// Recharge la liste avec le dernier numero connu.
  Future<void> refresh() async {
    final phone = _phone;
    if (phone == null) return;
    await load(phone);
  }

  /// Change le filtre fournisseur (null = Tous) et recharge.
  Future<void> filtrerParUnite(String? unite) async {
    if (_unite == unite) return;
    _unite = unite;
    await refresh();
  }

  void basculerSelection(String reference) {
    if (_selection.contains(reference)) {
      _selection.remove(reference);
    } else {
      _selection.add(reference);
    }
    notifyListeners();
  }

  /// Paie la selection. Regroupe les factures cochees par service et envoie un
  /// POST /pay-factures par service. Renvoie `true` si tout est passe, `false`
  /// avec un message metier FR ([errorMessage]) sinon.
  Future<bool> payerSelection() async {
    final phone = _phone;
    final aPayer = _facturesSelectionnees;
    if (phone == null || aPayer.isEmpty) return false;

    final Map<String, List<String>> parService = {};
    for (final f in aPayer) {
      parService.putIfAbsent(f.service, () => []).add(f.reference);
    }

    _isPaying = true;
    _errorMessage = null;
    notifyListeners();

    try {
      for (final entree in parService.entries) {
        await _walletApiService.payFactures(
          phoneNumber: phone,
          serviceName: entree.key,
          factureReferences: entree.value,
        );
      }
      _selection.clear();
      _isPaying = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isPaying = false;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Une erreur inattendue est survenue.';
      _isPaying = false;
      notifyListeners();
      return false;
    }
  }
}
