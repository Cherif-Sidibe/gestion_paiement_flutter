import 'package:flutter/material.dart';

import 'package:gestion_paiement_flutter/features/auth/screens/splash_screen.dart';
import 'package:gestion_paiement_flutter/features/auth/screens/auth_screen.dart';
import 'package:gestion_paiement_flutter/features/dashboard/screens/dashboard_screen.dart';
import 'package:gestion_paiement_flutter/features/transfers/screens/transfers_screen.dart';
import 'package:gestion_paiement_flutter/features/bills/screens/bills_screen.dart';
import 'package:gestion_paiement_flutter/features/history/screens/history_screen.dart';

/// Routage centralise de l'application (routes nommees + onGenerateRoute).
class AppRouter {
  static const String splashRoute = '/';
  static const String authRoute = '/auth';
  static const String dashboardRoute = '/dashboard';
  static const String transfersRoute = '/transfers';
  static const String billsRoute = '/bills';
  static const String historyRoute = '/history';

  static Route<dynamic> getRoute(RouteSettings settings) {
    switch (settings.name) {
      case splashRoute:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case authRoute:
        return MaterialPageRoute(builder: (_) => const AuthScreen());
      case dashboardRoute:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case transfersRoute:
        return MaterialPageRoute(builder: (_) => const TransfersScreen());
      case billsRoute:
        return MaterialPageRoute(builder: (_) => const BillsScreen());
      case historyRoute:
        return MaterialPageRoute(builder: (_) => const HistoryScreen());
      default:
        return _errorRoute(settings);
    }
  }

  static Route<dynamic> _errorRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Page introuvable')),
        body: Center(child: Text('Aucune route definie pour ${settings.name}')),
      ),
    );
  }
}
