import 'package:gestion_paiement_flutter/core/constants/api_constants.dart';
import 'package:gestion_paiement_flutter/core/network/api_client.dart';
import 'package:gestion_paiement_flutter/models/facture_model.dart';

/// Acces aux factures (controller /api/external/factures, relai payment-service).
class BillingApiService {
  final ApiClient _client;

  BillingApiService(this._client);

  Future<List<Facture>> getCurrentUnpaid(String walletCode, {String? unite}) async {
    final encoded = Uri.encodeComponent(walletCode);
    final json = await _client.get(
      '$externalFacturesPath/$encoded/current',
      query: unite == null ? null : {'unite': unite},
    );
    final body = ApiClient.unwrapBody(json) as List<dynamic>;
    return body.map((e) => Facture.fromJson(e as Map<String, dynamic>)).toList();
  }
}
