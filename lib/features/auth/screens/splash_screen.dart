import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gestion_paiement_flutter/features/auth/provider/auth_provider.dart';
import 'package:gestion_paiement_flutter/routes/app_router.dart';

/// Ecran de demarrage : restaure la session puis redirige.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final auth = context.read<AuthProvider>();
    await auth.restoreSession();
    if (!mounted) {
      return;
    }
    final destination = auth.phone == null ? AppRouter.authRoute : AppRouter.dashboardRoute;
    Navigator.pushReplacementNamed(context, destination);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_wallet, size: 72, color: colorScheme.onPrimary),
            const SizedBox(height: 16),
            Text(
              'BadWallet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
