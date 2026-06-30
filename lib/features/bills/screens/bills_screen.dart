import 'package:flutter/material.dart';

/// Paiement de factures (a implementer).
class BillsScreen extends StatelessWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Factures')),
      body: const Center(child: Text('Factures')),
    );
  }
}
