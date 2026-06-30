import 'package:flutter/material.dart';

/// Pave numerique personnalise pour la saisie du montant (sans clavier systeme).
///
/// Il n'edite aucun [TextField] : il pousse simplement des "touches" au parent
/// via [onKey] (un chiffre, '000') et [onDelete] (effacer le dernier chiffre).
/// Le parent garde l'etat de la chaine de chiffres et l'affiche en grand.
class AmountKeypad extends StatelessWidget {
  /// Appelee avec la sequence tapee : '0'..'9' ou '000'.
  final ValueChanged<String> onKey;

  /// Appelee a l'appui sur la touche effacer.
  final VoidCallback onDelete;

  const AmountKeypad({super.key, required this.onKey, required this.onDelete});

  static const List<String> _rows = ['123', '456', '789'];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in _rows)
          Row(
            children: [
              for (final char in row.split(''))
                _KeypadButton(label: char, onTap: () => onKey(char)),
            ],
          ),
        Row(
          children: [
            _KeypadButton(label: '000', onTap: () => onKey('000')),
            _KeypadButton(label: '0', onTap: () => onKey('0')),
            _KeypadButton(
              icon: Icons.backspace_outlined,
              onTap: onDelete,
            ),
          ],
        ),
      ],
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;

  const _KeypadButton({this.label, this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          height: 64,
          alignment: Alignment.center,
          child: icon != null
              ? Icon(icon, color: colorScheme.onSurface, size: 26)
              : Text(
                  label!,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
        ),
      ),
    );
  }
}
