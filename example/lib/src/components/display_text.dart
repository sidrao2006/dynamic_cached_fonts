import 'package:flutter/material.dart';

class DisplayText extends StatelessWidget {
  const DisplayText(
    this.text, {
    Key? key,
    required this.fontFamily,
    this.fontWeight = FontWeight.normal,
    this.fontStyle = FontStyle.normal,
    this.fontSize,
  }) : super(key: key);

  final String text;
  final String fontFamily;
  final FontWeight fontWeight;
  final FontStyle fontStyle;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize ?? Theme.of(context).textTheme.headline5!.fontSize,
          fontFamily: fontFamily,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
        ),
      ),
    );
  }
}
