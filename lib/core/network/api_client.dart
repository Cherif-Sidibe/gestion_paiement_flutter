import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:gestion_paiement_flutter/core/constants/api_constants.dart';
import 'package:gestion_paiement_flutter/core/network/api_exception.dart';

/// Client http centralise vers le back BadWallet.
///
/// Le back renvoie deux formes de reponse :
///  - RestResponse { success, status, message, body, timestamp } -> la donnee
///    utile est dans `body` (utiliser [unwrapBody]).
///  - PageResponse { data, totalElements, ... } -> renvoye tel quel (listing).
///
/// Sur un status >= 400, le message metier du back est extrait et releve via
/// [ApiException], pret a etre affiche en SnackBar ou en etat Error.
class ApiClient {
  final http.Client _httpClient;

  ApiClient({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    final uri = _buildUri(path, query);
    try {
      final response = await _httpClient.get(uri, headers: _jsonHeaders);
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Impossible de joindre le serveur. Verifiez votre connexion.');
    }
  }

  Future<dynamic> post(String path, {Object? body}) async {
    final uri = _buildUri(path, null);
    try {
      final response = await _httpClient.post(
        uri,
        headers: _jsonHeaders,
        body: body == null ? null : jsonEncode(body),
      );
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Impossible de joindre le serveur. Verifiez votre connexion.');
    }
  }

  /// Extrait `body` d'une enveloppe RestResponse ; renvoie [json] tel quel sinon.
  static dynamic unwrapBody(dynamic json) {
    if (json is Map<String, dynamic> && json.containsKey('body') && json.containsKey('success')) {
      return json['body'];
    }
    return json;
  }

  Uri _buildUri(String path, Map<String, dynamic>? query) {
    final base = Uri.parse('$apiBaseUrl$path');
    if (query == null || query.isEmpty) {
      return base;
    }
    final params = query.map((key, value) => MapEntry(key, '$value'));
    return base.replace(queryParameters: params);
  }

  dynamic _handleResponse(http.Response response) {
    final dynamic decoded = response.body.isEmpty ? null : jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode >= 400) {
      throw ApiException(_extractMessage(decoded, response.statusCode), statusCode: response.statusCode);
    }
    return decoded;
  }

  String _extractMessage(dynamic decoded, int statusCode) {
    if (decoded is Map<String, dynamic>) {
      final message = decoded['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }
    return 'Erreur serveur ($statusCode).';
  }

  void dispose() => _httpClient.close();
}
