import 'package:intl/intl.dart';

/// Formatte un montant avec separateur de milliers et la devise (ex 12 500 XOF).
String formatMontant(num montant, {String devise = 'XOF'}) {
  final formatter = NumberFormat.decimalPattern('fr_FR');
  return '${formatter.format(montant)} $devise';
}

/// Formatte une date ISO du back en date lisible (ex 30/06/2026 14:05).
String formatDateIso(String? isoDate) {
  if (isoDate == null || isoDate.isEmpty) {
    return '-';
  }
  final parsed = DateTime.tryParse(isoDate);
  if (parsed == null) {
    return isoDate;
  }
  return DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(parsed);
}
