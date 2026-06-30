/// Portefeuille tel que renvoye par le back (WalletResponseDto).
class Wallet {
  final int id;
  final String code;
  final String phoneNumber;
  final String email;
  final String currency;
  final double balance;
  final String? createdAt;

  const Wallet({
    required this.id,
    required this.code,
    required this.phoneNumber,
    required this.email,
    required this.currency,
    required this.balance,
    this.createdAt,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: (json['id'] as num).toInt(),
      code: json['code'] as String,
      phoneNumber: json['phoneNumber'] as String,
      email: json['email'] as String? ?? '',
      currency: json['currency'] as String? ?? 'XOF',
      balance: (json['balance'] as num).toDouble(),
      createdAt: json['createdAt'] as String?,
    );
  }
}

/// Solde seul (WalletBalanceResponseDto), renvoye par /balance.
class WalletBalance {
  final String code;
  final String phoneNumber;
  final double balance;
  final String currency;

  const WalletBalance({
    required this.code,
    required this.phoneNumber,
    required this.balance,
    required this.currency,
  });

  factory WalletBalance.fromJson(Map<String, dynamic> json) {
    return WalletBalance(
      code: json['code'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      balance: (json['balance'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'XOF',
    );
  }
}
