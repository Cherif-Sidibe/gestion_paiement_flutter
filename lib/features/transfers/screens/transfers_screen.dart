import 'package:flutter/material.dart';

/// Transferts entre portefeuilles (a implementer).
class TransfersScreen extends StatelessWidget {
  const TransfersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transferts')),
      body: const Center(child: Text('Transferts')),
    );
  }
}
