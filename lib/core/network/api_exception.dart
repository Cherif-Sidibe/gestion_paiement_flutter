/// Exception portant un message metier pret a afficher (SnackBar / etat Error).
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
