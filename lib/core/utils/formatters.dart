import 'package:intl/intl.dart';

/// Formatte un montant avec separateur de milliers et la devise (ex 12 500 XOF).
String formatMontant(num montant, {String devise = 'XOF'}) {
  final formatter = NumberFormat.decimalPattern('fr_FR');
  return '${formatter.format(montant)} $devise';
}

/// Formats renvoyes par le back (le back seede renvoie dd/MM/yyyy HH:mm:ss).
const List<String> _patternsBack = [
  'dd/MM/yyyy HH:mm:ss',
  'dd/MM/yyyy HH:mm',
  'dd/MM/yyyy',
];

/// Parse une date du back de maniere robuste : ISO d'abord, puis les formats
/// dd/MM/yyyy. Renvoie null si rien ne correspond.
DateTime? parseDateApi(String? raw) {
  if (raw == null || raw.isEmpty) {
    return null;
  }
  final iso = DateTime.tryParse(raw);
  if (iso != null) {
    return iso;
  }
  for (final pattern in _patternsBack) {
    try {
      return DateFormat(pattern, 'fr_FR').parseStrict(raw);
    } catch (_) {
      // pattern suivant
    }
  }
  return null;
}

/// Formatte une date du back en date lisible (ex 30/06/2026 14:05).
String formatDateIso(String? isoDate) {
  final parsed = parseDateApi(isoDate);
  if (parsed == null) {
    return (isoDate == null || isoDate.isEmpty) ? '-' : isoDate;
  }
  return DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(parsed);
}

/// Formatte une date du back en date courte (ex 30/06/2026).
String formatDateCourte(String? isoDate) {
  final parsed = parseDateApi(isoDate);
  if (parsed == null) {
    return (isoDate == null || isoDate.isEmpty) ? '-' : isoDate;
  }
  return DateFormat('dd/MM/yyyy', 'fr_FR').format(parsed);
}
