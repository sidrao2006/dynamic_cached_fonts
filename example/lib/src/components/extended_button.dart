import 'package:flutter/material.dart';

class ExtendedButton extends StatelessWidget {
  const ExtendedButton({
    Key key,
    this.onPressed,
    this.label,
    this.icon,
  }) : super(key: key);

  final VoidCallback onPressed;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      icon: Icon(icon),
      label: Text(label),
      onPressed: onPressed,
    );
  }
}
