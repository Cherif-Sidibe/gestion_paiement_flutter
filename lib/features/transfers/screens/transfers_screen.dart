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

  /// Etape courante : 0 = destinataire/description, 1 = montant (pave custom).
  int _etape = 0;

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

  /// Etape 1 -> 2 : valide le destinataire puis ferme le clavier systeme avant
  /// d'afficher le pave (jamais les deux a la fois).
  void _suivant() {
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

    FocusScope.of(context).unfocus();
    setState(() => _etape = 1);
  }

  /// Etape 2 -> 1 : retour a la saisie destinataire/description.
  void _retour() {
    setState(() => _etape = 0);
  }

  Future<void> _continuer() async {
    final destinataire = _destinataireController.text.trim();
    final courant = context.read<AuthProvider>().phone;

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
      appBar: AppBar(
        title: const Text('Transfert'),
        leading: _etape == 1
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _retour,
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _IndicateurEtape(etape: _etape),
            // IndexedStack : une seule etape visible a la fois. A l'etape 0
            // aucun pave custom ; a l'etape 1 aucun champ focusable -> jamais
            // de clavier systeme et de pave affiches en meme temps.
            Expanded(
              child: IndexedStack(
                index: _etape,
                sizing: StackFit.expand,
                children: [
                  _EtapeDestinataire(
                    destinataireController: _destinataireController,
                    descriptionController: _descriptionController,
                    onSuivant: _suivant,
                  ),
                  _EtapeMontant(
                    montant: _montant,
                    onKey: _onKey,
                    onDelete: _onDelete,
                    onContinuer: _continuer,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Indicateur des deux etapes du transfert (destinataire puis montant).
class _IndicateurEtape extends StatelessWidget {
  final int etape;

  const _IndicateurEtape({required this.etape});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget point(int index) => Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: index <= etape
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Column(
        children: [
          Row(children: [point(0), point(1)]),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              etape == 0 ? 'Etape 1 / 2 : Destinataire' : 'Etape 2 / 2 : Montant',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

/// Etape 1 : destinataire + description (claviers systeme), sans pave custom.
class _EtapeDestinataire extends StatelessWidget {
  final TextEditingController destinataireController;
  final TextEditingController descriptionController;
  final VoidCallback onSuivant;

  const _EtapeDestinataire({
    required this.destinataireController,
    required this.descriptionController,
    required this.onSuivant,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: destinataireController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Destinataire',
                    hintText: '+221770000000',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: descriptionController,
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
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(
            onPressed: onSuivant,
            child: const Text('Suivant'),
          ),
        ),
      ],
    );
  }
}

/// Etape 2 : montant pilote uniquement par le pave custom, aucun champ
/// focusable -> le clavier systeme ne peut pas s'ouvrir.
class _EtapeMontant extends StatelessWidget {
  final double montant;
  final ValueChanged<String> onKey;
  final VoidCallback onDelete;
  final VoidCallback onContinuer;

  const _EtapeMontant({
    required this.montant,
    required this.onKey,
    required this.onDelete,
    required this.onContinuer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(child: _MontantAffiche(montant: montant)),
        ),
        AmountKeypad(onKey: onKey, onDelete: onDelete),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(
            onPressed: onContinuer,
            child: const Text('Continuer'),
          ),
        ),
      ],
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
