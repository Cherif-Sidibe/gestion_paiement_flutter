import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gestion_paiement_flutter/core/utils/formatters.dart';
import 'package:gestion_paiement_flutter/features/auth/provider/auth_provider.dart';
import 'package:gestion_paiement_flutter/features/dashboard/provider/balance_provider.dart';
import 'package:gestion_paiement_flutter/features/dashboard/provider/transactions_provider.dart';
import 'package:gestion_paiement_flutter/features/transfers/provider/transfer_provider.dart';
import 'package:gestion_paiement_flutter/features/transfers/widgets/amount_keypad.dart';

/// Transfert d'argent : destinataire, montant via pave numerique custom,
/// description optionnelle, puis validation et confirmation avant envoi.
class TransfersScreen extends StatefulWidget {
  const TransfersScreen({super.key});

  @override
  State<TransfersScreen> createState() => _TransfersScreenState();
}

class _TransfersScreenState extends State<TransfersScreen> {
  static final _phonePattern = RegExp(r'^\+221[0-9]{9}$');
  static const _maxChiffres = 9;

  final _destinataireController = TextEditingController();
  final _descriptionController = TextEditingController();

  /// Chiffres bruts saisis au pave (sans separateur) ; '' = aucun montant.
  String _montantChiffres = '';

  @override
  void dispose() {
    _destinataireController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  double get _montant =>
      _montantChiffres.isEmpty ? 0 : double.parse(_montantChiffres);

  /// Ajoute une touche du pave (un chiffre ou '000'), en bloquant les zeros de
  /// tete et en plafonnant la longueur.
  void _onKey(String key) {
    if (_montantChiffres.isEmpty && (key == '0' || key == '000')) {
      return;
    }
    final next = _montantChiffres + key;
    if (next.length > _maxChiffres) {
      return;
    }
    setState(() => _montantChiffres = next);
  }

  void _onDelete() {
    if (_montantChiffres.isEmpty) {
      return;
    }
    setState(() => _montantChiffres =
        _montantChiffres.substring(0, _montantChiffres.length - 1));
  }

  void _erreur(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _continuer() async {
    FocusScope.of(context).unfocus();

    final destinataire = _destinataireController.text.trim();
    final courant = context.read<AuthProvider>().phone;

    if (destinataire.isEmpty) {
      _erreur('Veuillez saisir le numero du destinataire.');
      return;
    }
    if (!_phonePattern.hasMatch(destinataire)) {
      _erreur('Format attendu : +221XXXXXXXXX.');
      return;
    }
    if (destinataire == courant) {
      _erreur('Le destinataire doit etre different de l\'expediteur.');
      return;
    }
    if (_montant <= 0) {
      _erreur('Veuillez saisir un montant superieur a 0.');
      return;
    }

    final transfer = context.read<TransferProvider>();
    final existe = await transfer.verifierDestinataire(destinataire);
    if (!mounted) return;
    if (!existe) {
      _erreur(transfer.errorMessage ?? "Le destinataire n'existe pas.");
      return;
    }

    final confirme = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ConfirmationSheet(
        senderPhone: courant!,
        receiverPhone: destinataire,
        montant: _montant,
        description: _descriptionController.text.trim(),
      ),
    );

    if (!mounted || confirme != true) {
      return;
    }

    _erreur('Transfert effectue avec succes.');
    await Future.wait([
      context.read<BalanceProvider>().refresh(),
      context.read<TransactionsProvider>().refresh(),
    ]);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transfert')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _destinataireController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Destinataire',
                        hintText: '+221770000000',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 28),
                    _MontantAffiche(montant: _montant),
                    const SizedBox(height: 28),
                    TextField(
                      controller: _descriptionController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Description (optionnel)',
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AmountKeypad(onKey: _onKey, onDelete: _onDelete),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: FilledButton(
                onPressed: _continuer,
                child: const Text('Continuer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Montant en grand, formate (ex 12 500 XOF), au centre de l'ecran.
class _MontantAffiche extends StatelessWidget {
  final double montant;

  const _MontantAffiche({required this.montant});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final actif = montant > 0;

    return Column(
      children: [
        Text(
          'Montant',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        Text(
          formatMontant(montant),
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w700,
            color: actif ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Recapitulatif avant envoi : destinataire + montant + description, avec
/// gestion du chargement (bouton desactive + loader) et des erreurs metier.
class _ConfirmationSheet extends StatelessWidget {
  final String senderPhone;
  final String receiverPhone;
  final double montant;
  final String description;

  const _ConfirmationSheet({
    required this.senderPhone,
    required this.receiverPhone,
    required this.montant,
    required this.description,
  });

  Future<void> _confirmer(BuildContext context) async {
    final transfer = context.read<TransferProvider>();
    final ok = await transfer.envoyer(
      senderPhone: senderPhone,
      receiverPhone: receiverPhone,
      amount: montant,
    );
    if (!context.mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(transfer.errorMessage ?? 'Transfert impossible.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isLoading = context.watch<TransferProvider>().isLoading;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Confirmer le transfert',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          _LigneRecap(label: 'Destinataire', valeur: receiverPhone),
          _LigneRecap(label: 'Montant', valeur: formatMontant(montant)),
          if (description.isNotEmpty)
            _LigneRecap(label: 'Description', valeur: description),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: isLoading ? null : () => _confirmer(context),
            child: isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Confirmer'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: isLoading ? null : () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }
}

class _LigneRecap extends StatelessWidget {
  final String label;
  final String valeur;

  const _LigneRecap({required this.label, required this.valeur});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: colorScheme.onSurfaceVariant)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              valeur,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
