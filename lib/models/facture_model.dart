/// Facture telle que renvoyee par payment-service via le back (FactureDto).
class Facture {
  final int? id;
  final String reference;
  final String walletCode;
  final String service;
  final double montant;
  final String mois;
  final bool payee;
  final String? datePaiement;

  const Facture({
    this.id,
    required this.reference,
    required this.walletCode,
    required this.service,
    required this.montant,
    required this.mois,
    required this.payee,
    this.datePaiement,
  });

  factory Facture.fromJson(Map<String, dynamic> json) {
    return Facture(
      id: (json['id'] as num?)?.toInt(),
      reference: json['reference'] as String? ?? '',
      walletCode: json['walletCode'] as String? ?? '',
      service: json['service'] as String? ?? '',
      montant: (json['montant'] as num?)?.toDouble() ?? 0,
      mois: json['mois'] as String? ?? '',
      payee: json['payee'] as bool? ?? false,
      datePaiement: json['datePaiement'] as String?,
    );
  }
}
