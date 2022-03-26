import 'package:dynamic_cached_fonts/dynamic_cached_fonts.dart';
import 'package:flutter/material.dart';

import 'constants.dart';
import 'src/components.dart';
import 'src/demos.dart';

void main() {
  DynamicCachedFonts.toggleVerboseLogging(true);

  runApp(
    MaterialApp(
      title: 'Dynamic Cached Fonts Demo',
      home: const DynamicCachedFontsDemo1(),
      darkTheme: ThemeData.dark(),
    ),
  );
}

class DynamicCachedFontsDemo1 extends StatefulWidget {
  const DynamicCachedFontsDemo1({Key? key}) : super(key: key);

  @override
  _DynamicCachedFontsDemo1State createState() => _DynamicCachedFontsDemo1State();
}

class _DynamicCachedFontsDemo1State extends State<DynamicCachedFontsDemo1> {
  @override
  void initState() {
    final DynamicCachedFonts dynamicCachedFont = DynamicCachedFonts(
      fontFamily: cascadiaCode,
      url: cascadiaCodeUrl,
    );
    dynamicCachedFont.load();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(demoTitle),
      ),
      body: const Center(
        child: DisplayText(
          'The text is being displayed in $cascadiaCode which is being dynamically loaded and cached',
          fontFamily: cascadiaCode,
        ),
      ),
      floatingActionButton: ExtendedButton(
        icon: Icons.navigate_next,
        label: 'Next Example',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<DynamicCachedFontsDemo2>(
            builder: (_) => const DynamicCachedFontsDemo2(),
          ),
        ),
      ),
    );
  }
}
