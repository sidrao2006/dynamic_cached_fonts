import 'package:dynamic_cached_fonts/dynamic_cached_fonts.dart';
import 'package:flutter/material.dart';

import 'package:dynamic_cached_fonts_example/constants.dart';

import '../components.dart';
import 'download_use_family_stream_demo.dart';

class DynamicCachedFontsDemo5 extends StatefulWidget {
  const DynamicCachedFontsDemo5({Key? key}) : super(key: key);

  @override
  _DynamicCachedFontsDemo5State createState() => _DynamicCachedFontsDemo5State();
}

class _DynamicCachedFontsDemo5State extends State<DynamicCachedFontsDemo5> {
  @override
  void initState() {
    final DynamicCachedFonts dynamicCachedFont = DynamicCachedFonts.family(
      urls: <String>[
        firaSansBoldUrl,
        firaSansItalicUrl,
        firaSansRegularUrl,
        firaSansThinUrl,
      ],
      fontFamily: firaSans,
    );
    dynamicCachedFont.load();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '$demoTitle - Load multiple fonts as a family',
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <DisplayText>[
          DisplayText(
            'The text is being displayed in $firaSans bold which is being dynamically loaded cached.',
            fontFamily: firaSans,
            fontWeight: FontWeight.bold,
            fontSize: Theme.of(context).textTheme.headline6!.fontSize,
          ),
          DisplayText(
            'The text is being displayed in $firaSans italic which is being dynamically loaded cached.',
            fontFamily: firaSans,
            fontStyle: FontStyle.italic,
            fontSize: Theme.of(context).textTheme.headline6!.fontSize,
          ),
          DisplayText(
            'The text is being displayed in $firaSans regular which is being dynamically loaded cached.',
            fontFamily: firaSans,
            fontSize: Theme.of(context).textTheme.headline6!.fontSize,
          ),
          DisplayText(
            'The text is being displayed in $firaSans thin which is being dynamically loaded cached.',
            fontFamily: firaSans,
            fontWeight: FontWeight.w100,
            fontSize: Theme.of(context).textTheme.headline6!.fontSize,
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: ExtendedButton(
        icon: Icons.navigate_next,
        label: 'Next Example',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<DynamicCachedFontsDemo6>(
            builder: (_) => const DynamicCachedFontsDemo6(),
          ),
        ),
      ),
    );
  }
}
