import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    Key? key,
    required this.onPressed,
    this.title = 'Download',
    this.icon,
  }) : super(key: key);

  final VoidCallback? onPressed;
  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon ?? Icons.download_rounded),
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge,
          )
        ],
      ),
    );
  }
}
