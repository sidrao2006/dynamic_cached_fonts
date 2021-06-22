import 'package:flutter/material.dart';

class ExtendedButton extends StatelessWidget {
  const ExtendedButton({
    Key? key,
    required this.onPressed,
    required this.label,
    this.icon,
  }) : super(key: key);

  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      icon: icon == null ? null : Icon(icon),
      label: Text(label),
      onPressed: onPressed,
    );
  }
}
