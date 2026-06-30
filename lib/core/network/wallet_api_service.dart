import 'package:gestion_paiement_flutter/core/constants/api_constants.dart';
import 'package:gestion_paiement_flutter/core/network/api_client.dart';
import 'package:gestion_paiement_flutter/models/transaction_model.dart';
import 'package:gestion_paiement_flutter/models/wallet_model.dart';

/// Acces aux ressources wallet et transactions (controllers /api/wallets).
///
/// Le numero de telephone contient un '+' : il est encode par segment de path
/// pour ne pas casser l'URL.
class WalletApiService {
  final ApiClient _client;

  WalletApiService(this._client);

  Future<WalletBalance> getBalance(String phone) async {
    final encoded = Uri.encodeComponent(phone);
    final json = await _client.get('$walletsPath/$encoded/balance');
    final body = ApiClient.unwrapBody(json) as Map<String, dynamic>;
    return WalletBalance.fromJson(body);
  }

  Future<Wallet> getWallet(String phone) async {
    final encoded = Uri.encodeComponent(phone);
    final json = await _client.get('$walletsPath/$encoded');
    final body = ApiClient.unwrapBody(json) as Map<String, dynamic>;
    return Wallet.fromJson(body);
  }

  Future<List<Transaction>> getTransactions(String phone) async {
    final encoded = Uri.encodeComponent(phone);
    final json = await _client.get('$walletsPath/$encoded/transactions');
    final body = ApiClient.unwrapBody(json) as List<dynamic>;
    return body.map((e) => Transaction.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Transfere [amount] de [senderPhone] vers [receiverPhone].
  ///
  /// En cas de solde insuffisant ou d'erreur metier, le back renvoie un status
  /// >= 400 et [ApiClient] releve le message via [ApiException].
  Future<void> transfer({
    required String senderPhone,
    required String receiverPhone,
    required double amount,
  }) async {
    await _client.post('$walletsPath/transfer', body: {
      'senderPhone': senderPhone,
      'receiverPhone': receiverPhone,
      'amount': amount,
    });
  }
}
