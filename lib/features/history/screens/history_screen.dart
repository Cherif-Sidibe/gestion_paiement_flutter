import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:gestion_paiement_flutter/core/state/view_state.dart';
import 'package:gestion_paiement_flutter/core/utils/formatters.dart';
import 'package:gestion_paiement_flutter/features/auth/provider/auth_provider.dart';
import 'package:gestion_paiement_flutter/features/dashboard/provider/transactions_provider.dart';
import 'package:gestion_paiement_flutter/models/transaction_model.dart';

const Color _vertEntree = Color(0xFF1E9E5A);
const Color _rougeSortie = Color(0xFFD64545);

/// Filtre par type de transaction (Transfert regroupe envoye + recu).
enum _TypeFiltre { tous, depot, retrait, transfert, paiement }

/// Filtre par date (raccourcis + intervalle personnalise).
enum _DateFiltre { tout, septJours, ceMois, personnalise }

/// Historique complet des transactions de la wallet courante, avec filtres
/// (type + date) combines et appliques cote client.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  _TypeFiltre _type = _TypeFiltre.tous;
  _DateFiltre _date = _DateFiltre.tout;
  DateTimeRange? _intervalle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final phone = context.read<AuthProvider>().phone;
    if (phone == null) return;
    await context.read<TransactionsProvider>().loadTransactions(phone);
  }

  bool get _filtresActifs =>
      _type != _TypeFiltre.tous || _date != _DateFiltre.tout;

  void _reinitialiser() {
    setState(() {
      _type = _TypeFiltre.tous;
      _date = _DateFiltre.tout;
      _intervalle = null;
    });
  }

  Future<void> _choisirIntervalle() async {
    final maintenant = DateTime.now();
    final choix = await showDateRangePicker(
      context: context,
      firstDate: DateTime(maintenant.year - 5),
      lastDate: maintenant,
      initialDateRange: _intervalle,
    );
    if (choix != null) {
      setState(() {
        _intervalle = choix;
        _date = _DateFiltre.personnalise;
      });
    }
  }

  void _selectionnerDate(_DateFiltre valeur) {
    if (valeur == _DateFiltre.personnalise) {
      _choisirIntervalle();
      return;
    }
    setState(() {
      _date = valeur;
      _intervalle = null;
    });
  }

  /// Applique les deux filtres (type ET date) sur la liste deja chargee.
  List<Transaction> _appliquerFiltres(List<Transaction> source) {
    return source.where((tx) {
      return _correspondType(tx) && _correspondDate(tx);
    }).toList();
  }

  bool _correspondType(Transaction tx) {
    switch (_type) {
      case _TypeFiltre.tous:
        return true;
      case _TypeFiltre.depot:
        return tx.type == TransactionType.depot;
      case _TypeFiltre.retrait:
        return tx.type == TransactionType.retrait;
      case _TypeFiltre.transfert:
        return tx.type == TransactionType.transfertEnvoye ||
            tx.type == TransactionType.transfertRecu;
      case _TypeFiltre.paiement:
        return tx.type == TransactionType.paiement;
    }
  }

  bool _correspondDate(Transaction tx) {
    final intervalle = _intervalleActif();
    if (intervalle == null) return true;
    final date = DateTime.tryParse(tx.createdAt ?? '');
    if (date == null) return false;
    return !date.isBefore(intervalle.start) && !date.isAfter(intervalle.end);
  }

  /// Convertit le filtre date en intervalle concret (null = pas de filtre).
  DateTimeRange? _intervalleActif() {
    final maintenant = DateTime.now();
    final finJour = DateTime(maintenant.year, maintenant.month, maintenant.day, 23, 59, 59);
    switch (_date) {
      case _DateFiltre.tout:
        return null;
      case _DateFiltre.septJours:
        return DateTimeRange(
          start: finJour.subtract(const Duration(days: 7)),
          end: finJour,
        );
      case _DateFiltre.ceMois:
        return DateTimeRange(
          start: DateTime(maintenant.year, maintenant.month, 1),
          end: finJour,
        );
      case _DateFiltre.personnalise:
        final i = _intervalle;
        if (i == null) return null;
        return DateTimeRange(
          start: DateTime(i.start.year, i.start.month, i.start.day),
          end: DateTime(i.end.year, i.end.month, i.end.day, 23, 59, 59),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique'),
        actions: [
          if (_filtresActifs)
            IconButton(
              tooltip: 'Reinitialiser les filtres',
              icon: const Icon(Icons.filter_alt_off_outlined),
              onPressed: _reinitialiser,
            ),
        ],
      ),
      body: Column(
        children: [
          _Filtres(
            type: _type,
            date: _date,
            intervalle: _intervalle,
            onType: (v) => setState(() => _type = v),
            onDate: _selectionnerDate,
          ),
          const Divider(height: 1),
          Expanded(child: _Contenu(provider: provider, filtrer: _appliquerFiltres, onRefresh: _load)),
        ],
      ),
    );
  }
}

/// Barre de filtres : chips de type puis chips de date.
class _Filtres extends StatelessWidget {
  final _TypeFiltre type;
  final _DateFiltre date;
  final DateTimeRange? intervalle;
  final ValueChanged<_TypeFiltre> onType;
  final ValueChanged<_DateFiltre> onDate;

  const _Filtres({
    required this.type,
    required this.date,
    required this.intervalle,
    required this.onType,
    required this.onDate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in _typeLibelles.entries)
                ChoiceChip(
                  label: Text(entry.value),
                  selected: type == entry.key,
                  onSelected: (_) => onType(entry.key),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in _dateRaccourcis.entries)
                ChoiceChip(
                  label: Text(entry.value),
                  selected: date == entry.key,
                  onSelected: (_) => onDate(entry.key),
                ),
              if (date == _DateFiltre.personnalise && intervalle != null)
                InputChip(
                  avatar: const Icon(Icons.event_rounded, size: 18),
                  label: Text(
                    '${_jourMois(intervalle!.start)} – ${_jourMois(intervalle!.end)}',
                  ),
                  selected: true,
                  onSelected: (_) => onDate(_DateFiltre.personnalise),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () => onDate(_DateFiltre.tout),
                  tooltip: 'Modifier la periode',
                )
              else
                ActionChip(
                  avatar: const Icon(Icons.date_range_rounded, size: 18),
                  label: const Text('Choisir une periode'),
                  onPressed: () => onDate(_DateFiltre.personnalise),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Date au format court francais (ex "1 juin"), pour l'intervalle choisi.
String _jourMois(DateTime date) {
  return DateFormat('d MMM', 'fr_FR').format(date);
}

const Map<_TypeFiltre, String> _typeLibelles = {
  _TypeFiltre.tous: 'Tous',
  _TypeFiltre.depot: 'Depot',
  _TypeFiltre.retrait: 'Retrait',
  _TypeFiltre.transfert: 'Transfert',
  _TypeFiltre.paiement: 'Paiement',
};

const Map<_DateFiltre, String> _dateRaccourcis = {
  _DateFiltre.tout: 'Tout',
  _DateFiltre.septJours: '7 derniers jours',
  _DateFiltre.ceMois: 'Ce mois',
};

/// Gere les etats (loading / error / vide / liste) + pull-to-refresh.
class _Contenu extends StatelessWidget {
  final TransactionsProvider provider;
  final List<Transaction> Function(List<Transaction>) filtrer;
  final Future<void> Function() onRefresh;

  const _Contenu({required this.provider, required this.filtrer, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    switch (provider.state) {
      case ViewState.initial:
      case ViewState.loading:
        return const Center(child: CircularProgressIndicator());
      case ViewState.error:
        return _MessageCentre(
          texte: provider.errorMessage ?? 'Impossible de charger l\'historique.',
          action: TextButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Reessayer'),
          ),
        );
      case ViewState.loaded:
        if (provider.all.isEmpty) {
          return const _MessageCentre(texte: 'Aucune transaction');
        }
        final items = filtrer(provider.all);
        if (items.isEmpty) {
          return const _MessageCentre(texte: 'Aucun resultat pour ces filtres');
        }
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            itemBuilder: (_, i) => _TransactionTile(transaction: items[i]),
          ),
        );
    }
  }
}

class _MessageCentre extends StatelessWidget {
  final String texte;
  final Widget? action;

  const _MessageCentre({required this.texte, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(texte, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 8), action!],
        ],
      ),
    );
  }
}

/// Ligne d'historique : icone directionnelle, libelle, frais, date,
/// montant signe et code couleur (vert entree / rouge sortie).
class _TransactionTile extends StatelessWidget {
  final Transaction transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final entree = _estEntree(transaction.type);
    final couleur = entree ? _vertEntree : _rougeSortie;
    final signe = entree ? '+' : '-';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: couleur.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              entree ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: couleur,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _libelle(transaction),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  formatDateIso(transaction.createdAt),
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                ),
                if (transaction.fees > 0)
                  Text(
                    'Frais : ${formatMontant(transaction.fees)}',
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$signe${formatMontant(transaction.amount)}',
            style: TextStyle(color: couleur, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

bool _estEntree(TransactionType type) {
  return type == TransactionType.depot || type == TransactionType.transfertRecu;
}

String _libelle(Transaction transaction) {
  switch (transaction.type) {
    case TransactionType.depot:
      return 'Depot';
    case TransactionType.retrait:
      return 'Retrait';
    case TransactionType.transfertEnvoye:
      return 'Transfert envoye';
    case TransactionType.transfertRecu:
      return 'Transfert recu';
    case TransactionType.paiement:
      return 'Paiement';
    case TransactionType.inconnu:
      return transaction.typeLabel;
  }
}
