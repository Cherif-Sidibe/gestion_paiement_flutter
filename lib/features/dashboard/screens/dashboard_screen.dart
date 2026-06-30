import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gestion_paiement_flutter/core/state/view_state.dart';
import 'package:gestion_paiement_flutter/core/utils/formatters.dart';
import 'package:gestion_paiement_flutter/features/auth/provider/auth_provider.dart';
import 'package:gestion_paiement_flutter/features/dashboard/provider/balance_provider.dart';
import 'package:gestion_paiement_flutter/routes/app_router.dart';

/// Tableau de bord : solde courant et acces aux operations.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBalance());
  }

  Future<void> _loadBalance() async {
    final phone = context.read<AuthProvider>().phone;
    if (phone != null) {
      await context.read<BalanceProvider>().loadBalance(phone);
    }
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
        onRefresh: _loadBalance,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const _BalanceCard(),
            const SizedBox(height: 24),
            Text('Operations', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _ActionTile(
              icon: Icons.send,
              label: 'Transferts',
              route: AppRouter.transfersRoute,
            ),
            _ActionTile(
              icon: Icons.receipt_long,
              label: 'Factures',
              route: AppRouter.billsRoute,
            ),
            _ActionTile(
              icon: Icons.history,
              label: 'Historique',
              route: AppRouter.historyRoute,
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BalanceProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Solde disponible',
              style: TextStyle(color: colorScheme.onPrimary.withValues(alpha: 0.8)),
            ),
            const SizedBox(height: 12),
            _BalanceContent(provider: provider),
          ],
        ),
      ),
    );
  }
}

class _BalanceContent extends StatelessWidget {
  final BalanceProvider provider;

  const _BalanceContent({required this.provider});

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    switch (provider.state) {
      case ViewState.loading:
      case ViewState.initial:
        return SizedBox(
          height: 36,
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: onPrimary),
            ),
          ),
        );
      case ViewState.error:
        return Text(
          provider.errorMessage ?? 'Erreur de chargement.',
          style: TextStyle(color: onPrimary),
        );
      case ViewState.loaded:
        final balance = provider.balance;
        return Text(
          balance == null ? '-' : formatMontant(balance.balance, devise: balance.currency),
          style: TextStyle(color: onPrimary, fontSize: 30, fontWeight: FontWeight.w700),
        );
    }
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;

  const _ActionTile({required this.icon, required this.label, required this.route});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.pushNamed(context, route),
      ),
    );
  }
}
