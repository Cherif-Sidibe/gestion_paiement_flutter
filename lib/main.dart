import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:gestion_paiement_flutter/core/network/api_client.dart';
import 'package:gestion_paiement_flutter/core/network/billing_api_service.dart';
import 'package:gestion_paiement_flutter/core/network/wallet_api_service.dart';
import 'package:gestion_paiement_flutter/core/storage/session_storage.dart';
import 'package:gestion_paiement_flutter/core/theme/app_theme.dart';
import 'package:gestion_paiement_flutter/features/auth/provider/auth_provider.dart';
import 'package:gestion_paiement_flutter/features/bills/provider/bills_provider.dart';
import 'package:gestion_paiement_flutter/features/dashboard/provider/balance_provider.dart';
import 'package:gestion_paiement_flutter/features/dashboard/provider/transactions_provider.dart';
import 'package:gestion_paiement_flutter/features/transfers/provider/transfer_provider.dart';
import 'package:gestion_paiement_flutter/routes/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);

  final apiClient = ApiClient();
  final walletApiService = WalletApiService(apiClient);
  final billingApiService = BillingApiService(apiClient);
  final sessionStorage = SessionStorage();

  runApp(BadWalletApp(
    walletApiService: walletApiService,
    billingApiService: billingApiService,
    sessionStorage: sessionStorage,
  ));
}

class BadWalletApp extends StatelessWidget {
  final WalletApiService walletApiService;
  final BillingApiService billingApiService;
  final SessionStorage sessionStorage;

  const BadWalletApp({
    super.key,
    required this.walletApiService,
    required this.billingApiService,
    required this.sessionStorage,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<WalletApiService>.value(value: walletApiService),
        Provider<BillingApiService>.value(value: billingApiService),
        Provider<SessionStorage>.value(value: sessionStorage),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(walletApiService, sessionStorage),
        ),
        ChangeNotifierProvider(
          create: (_) => BalanceProvider(walletApiService),
        ),
        ChangeNotifierProvider(
          create: (_) => TransactionsProvider(walletApiService),
        ),
        ChangeNotifierProvider(
          create: (_) => TransferProvider(walletApiService),
        ),
        ChangeNotifierProvider(
          create: (_) => BillsProvider(walletApiService, billingApiService),
        ),
      ],
      child: MaterialApp(
        title: 'BadWallet',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        locale: const Locale('fr', 'FR'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('fr'), Locale('fr', 'FR')],
        initialRoute: AppRouter.splashRoute,
        onGenerateRoute: AppRouter.getRoute,
      ),
    );
  }
}
