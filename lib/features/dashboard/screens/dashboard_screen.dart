import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gestion_paiement_flutter/core/state/view_state.dart';
import 'package:gestion_paiement_flutter/core/utils/formatters.dart';
import 'package:gestion_paiement_flutter/features/auth/provider/auth_provider.dart';
import 'package:gestion_paiement_flutter/features/dashboard/provider/balance_provider.dart';
import 'package:gestion_paiement_flutter/features/dashboard/provider/transactions_provider.dart';
import 'package:gestion_paiement_flutter/models/transaction_model.dart';
import 'package:gestion_paiement_flutter/routes/app_router.dart';

/// Tableau de bord : carte solde masquable, actions rapides et apercu des
/// dernieres transactions.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  /// Etat local du toggle oeil : masque/affiche le solde.
  bool _soldeMasque = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final phone = context.read<AuthProvider>().phone;
    if (phone == null) return;
    await Future.wait([
      context.read<BalanceProvider>().loadBalance(phone),
      context.read<TransactionsProvider>().loadTransactions(phone),
    ]);
  }

  /// Rafraichit solde et transactions au retour sur le dashboard.
  Future<void> _refresh() async {
    await Future.wait([
      context.read<BalanceProvider>().refresh(),
      context.read<TransactionsProvider>().refresh(),
    ]);
  }

  void _ouvrir(String route) {
    Navigator.pushNamed(context, route).then((_) {
      if (mounted) _refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon portefeuille'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRouter.authRoute);
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _BalanceCard(
              masque: _soldeMasque,
              onToggle: () => setState(() => _soldeMasque = !_soldeMasque),
            ),
            const SizedBox(height: 28),
            _QuickActions(onTap: _ouvrir),
            const SizedBox(height: 28),
            const _RecentTransactions(),
          ],
        ),
      ),
    );
  }
}

/// Bloc 1 : carte solde coloree, masquable via l'icone oeil.
class _BalanceCard extends StatelessWidget {
  final bool masque;
  final VoidCallback onToggle;

  const _BalanceCard({required this.masque, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final provider = context.watch<BalanceProvider>();
    final onPrimary = colorScheme.onPrimary;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primary, colorScheme.tertiary],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Solde disponible',
                  style: TextStyle(
                    color: onPrimary.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                onPressed: onToggle,
                icon: Icon(
                  masque ? Icons.visibility_off : Icons.visibility,
                  color: onPrimary,
                ),
                tooltip: masque ? 'Afficher le solde' : 'Masquer le solde',
              ),
            ],
          ),
          const SizedBox(height: 8),
          _BalanceValue(provider: provider, masque: masque),
          const SizedBox(height: 24),
          _WalletMeta(provider: provider),
        ],
      ),
    );
  }
}

class _BalanceValue extends StatelessWidget {
  final BalanceProvider provider;
  final bool masque;

  const _BalanceValue({required this.provider, required this.masque});

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    switch (provider.state) {
      case ViewState.loading:
      case ViewState.initial:
        return SizedBox(
          height: 40,
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              height: 26,
              width: 26,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: onPrimary),
            ),
          ),
        );
      case ViewState.error:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              provider.errorMessage ?? 'Solde indisponible.',
              style: TextStyle(color: onPrimary),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: provider.refresh,
              icon: Icon(Icons.refresh, color: onPrimary),
              label: Text('Reessayer', style: TextStyle(color: onPrimary)),
            ),
          ],
        );
      case ViewState.loaded:
        final balance = provider.balance;
        final devise = balance?.currency ?? 'XOF';
        final texte = masque
            ? '••••• $devise'
            : (balance == null ? '-' : formatMontant(balance.balance, devise: devise));
        return Text(
          texte,
          style: TextStyle(
            color: onPrimary,
            fontSize: 34,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        );
    }
  }
}

class _WalletMeta extends StatelessWidget {
  final BalanceProvider provider;

  const _WalletMeta({required this.provider});

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final balance = provider.balance;
    final phone = balance?.phoneNumber ?? context.read<AuthProvider>().phone ?? '';
    final code = balance?.code ?? '';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.phone_iphone, size: 16, color: onPrimary.withValues(alpha: 0.85)),
            const SizedBox(width: 6),
            Text(
              phone.isEmpty ? '-' : phone,
              style: TextStyle(color: onPrimary.withValues(alpha: 0.95)),
            ),
          ],
        ),
        if (code.isNotEmpty)
          Text(
            code,
            style: TextStyle(
              color: onPrimary.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
      ],
    );
  }
}

/// Bloc 2 : boutons d'actions rapides (Transferer, Payer, Historique).
class _QuickActions extends StatelessWidget {
  final void Function(String route) onTap;

  const _QuickActions({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.send_rounded,
            label: 'Transferer',
            onTap: () => onTap(AppRouter.transfersRoute),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.receipt_long_rounded,
            label: 'Payer',
            onTap: () => onTap(AppRouter.billsRoute),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.history_rounded,
            label: 'Historique',
            onTap: () => onTap(AppRouter.historyRoute),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: colorScheme.primary),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bloc 3 : apercu des 5 dernieres transactions.
class _RecentTransactions extends StatelessWidget {
  const _RecentTransactions();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionsProvider>();
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Dernieres transactions', style: textTheme.titleMedium),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRouter.historyRoute),
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _TransactionsContent(provider: provider),
      ],
    );
  }
}

class _TransactionsContent extends StatelessWidget {
  final TransactionsProvider provider;

  const _TransactionsContent({required this.provider});

  @override
  Widget build(BuildContext context) {
    switch (provider.state) {
      case ViewState.loading:
      case ViewState.initial:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CircularProgressIndicator()),
        );
      case ViewState.error:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Text(
                provider.errorMessage ?? 'Impossible de charger les transactions.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: provider.refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Reessayer'),
              ),
            ],
          ),
        );
      case ViewState.loaded:
        final items = provider.latest;
        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: Text('Aucune transaction pour le moment.')),
          );
        }
        return Column(
          children: [
            for (final tx in items) _TransactionTile(transaction: tx),
          ],
        );
    }
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final entree = _estEntree(transaction.type);
    final couleur = entree ? const Color(0xFF1E9E5A) : const Color(0xFFD64545);
    final signe = entree ? '+' : '-';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
                  formatDateCourte(transaction.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
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
