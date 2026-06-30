import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gestion_paiement_flutter/core/state/view_state.dart';
import 'package:gestion_paiement_flutter/core/utils/formatters.dart';
import 'package:gestion_paiement_flutter/features/auth/provider/auth_provider.dart';
import 'package:gestion_paiement_flutter/features/bills/provider/bills_provider.dart';
import 'package:gestion_paiement_flutter/features/dashboard/provider/balance_provider.dart';
import 'package:gestion_paiement_flutter/features/dashboard/provider/transactions_provider.dart';
import 'package:gestion_paiement_flutter/models/facture_model.dart';

/// Factures impayees du mois : filtre par fournisseur, selection multiple et
/// paiement en lot (regroupe par service).
class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  /// Fournisseurs geres par le back. `null` = Tous.
  static const _fournisseurs = <(String, String?)>[
    ('Tous', null),
    ('ISM', 'ISM'),
    ('WOYAFAL', 'WOYAFAL'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final phone = context.read<AuthProvider>().phone;
      if (phone != null) {
        context.read<BillsProvider>().load(phone);
      }
    });
  }

  Future<void> _payer() async {
    final bills = context.read<BillsProvider>();
    final ok = await bills.payerSelection();
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Factures payees avec succes.')),
      );
      await Future.wait([
        bills.refresh(),
        context.read<BalanceProvider>().refresh(),
        context.read<TransactionsProvider>().refresh(),
      ]);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(bills.errorMessage ?? 'Paiement impossible.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bills = context.watch<BillsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Factures')),
      body: SafeArea(
        child: Column(
          children: [
            _FiltreFournisseur(
              fournisseurs: _fournisseurs,
              selection: bills.unite,
              onChange: bills.isPaying ? null : bills.filtrerParUnite,
            ),
            Expanded(child: _Corps(bills: bills)),
            if (bills.nombreSelectionne > 0)
              _RecapPaiement(
                nombre: bills.nombreSelectionne,
                total: bills.totalSelectionne,
                isPaying: bills.isPaying,
                onPayer: _payer,
              ),
          ],
        ),
      ),
    );
  }
}

/// Selecteur de fournisseur (chips Tous / ISM / WOYAFAL).
class _FiltreFournisseur extends StatelessWidget {
  final List<(String, String?)> fournisseurs;
  final String? selection;
  final ValueChanged<String?>? onChange;

  const _FiltreFournisseur({
    required this.fournisseurs,
    required this.selection,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          for (final (label, unite) in fournisseurs)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(label),
                selected: selection == unite,
                onSelected:
                    onChange == null ? null : (_) => onChange!(unite),
              ),
            ),
        ],
      ),
    );
  }
}

/// Corps selon l'etat : loader, erreur + reessayer, vide ou liste.
class _Corps extends StatelessWidget {
  final BillsProvider bills;

  const _Corps({required this.bills});

  @override
  Widget build(BuildContext context) {
    switch (bills.state) {
      case ViewState.initial:
      case ViewState.loading:
        return const Center(child: CircularProgressIndicator());
      case ViewState.error:
        return _Erreur(
          message: bills.errorMessage ?? 'Une erreur est survenue.',
          onReessayer: bills.refresh,
        );
      case ViewState.loaded:
        if (bills.factures.isEmpty) {
          return const Center(child: Text('Aucune facture impayee'));
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          itemCount: bills.factures.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, index) {
            final facture = bills.factures[index];
            return _LigneFacture(
              facture: facture,
              cochee: bills.estSelectionnee(facture.reference),
              onChange: (_) => bills.basculerSelection(facture.reference),
            );
          },
        );
    }
  }
}

/// Une ligne facture : checkbox + reference + service + montant + mois.
class _LigneFacture extends StatelessWidget {
  final Facture facture;
  final bool cochee;
  final ValueChanged<bool?> onChange;

  const _LigneFacture({
    required this.facture,
    required this.cochee,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: CheckboxListTile(
        value: cochee,
        onChanged: onChange,
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(
          facture.reference,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${facture.service} - ${facture.mois}',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        secondary: Text(
          formatMontant(facture.montant),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

/// Message d'erreur FR centre avec bouton Reessayer.
class _Erreur extends StatelessWidget {
  final String message;
  final Future<void> Function() onReessayer;

  const _Erreur({required this.message, required this.onReessayer});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onReessayer,
              child: const Text('Reessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Recap bas d'ecran : nombre selectionne + total + bouton Payer la selection.
class _RecapPaiement extends StatelessWidget {
  final int nombre;
  final double total;
  final bool isPaying;
  final Future<void> Function() onPayer;

  const _RecapPaiement({
    required this.nombre,
    required this.total,
    required this.isPaying,
    required this.onPayer,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$nombre facture${nombre > 1 ? 's' : ''} selectionnee${nombre > 1 ? 's' : ''}',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              Text(
                formatMontant(total),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: isPaying ? null : onPayer,
            child: isPaying
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Payer la selection'),
          ),
        ],
      ),
    );
  }
}
