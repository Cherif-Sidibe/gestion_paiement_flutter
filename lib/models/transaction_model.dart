/// Type metier d'une transaction (libelles du back).
enum TransactionType { depot, retrait, transfertEnvoye, transfertRecu, paiement, inconnu }

TransactionType transactionTypeFromString(String? value) {
  switch (value) {
    case 'DEPOT':
      return TransactionType.depot;
    case 'RETRAIT':
      return TransactionType.retrait;
    case 'TRANSFERT_ENVOYE':
      return TransactionType.transfertEnvoye;
    case 'TRANSFERT_RECU':
      return TransactionType.transfertRecu;
    case 'PAIEMENT':
      return TransactionType.paiement;
    default:
      return TransactionType.inconnu;
  }
}

/// Ligne d'historique (TransactionResponseDto).
/// paymentMethod n'est renseigne que pour les depots.
class Transaction {
  final int id;
  final TransactionType type;
  final String typeLabel;
  final double amount;
  final double fees;
  final String? paymentMethod;
  final String? createdAt;

  const Transaction({
    required this.id,
    required this.type,
    required this.typeLabel,
    required this.amount,
    required this.fees,
    this.paymentMethod,
    this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    final rawType = json['type'] as String?;
    return Transaction(
      id: (json['id'] as num).toInt(),
      type: transactionTypeFromString(rawType),
      typeLabel: rawType ?? 'INCONNU',
      amount: (json['amount'] as num).toDouble(),
      fees: (json['fees'] as num?)?.toDouble() ?? 0,
      paymentMethod: json['paymentMethod'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }
}
