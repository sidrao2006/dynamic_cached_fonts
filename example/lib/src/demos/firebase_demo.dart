import 'package:dynamic_cached_fonts/dynamic_cached_fonts.dart';
import 'package:dynamic_cached_fonts_example/constants.dart';
import 'package:dynamic_cached_fonts_example/firebase_options.dart';
import 'package:dynamic_cached_fonts_example/src/demos/multi_font_loading_demo.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../components.dart';

class DynamicCachedFontsDemo4 extends StatefulWidget {
  const DynamicCachedFontsDemo4({Key? key}) : super(key: key);

  @override
  _DynamicCachedFontsDemo4State createState() => _DynamicCachedFontsDemo4State();
}

class _DynamicCachedFontsDemo4State extends State<DynamicCachedFontsDemo4> {
  @override
  void initState() {
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform).then(
      (_) => DynamicCachedFonts.fromFirebase(
        bucketUrl: firaCodeUrl,
        fontFamily: firaCode,
      ).load(),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('$demoTitle - Firebase Storage'),
      ),
      body: const Center(
        child: DisplayText(
          'The text is being displayed in $firaCode which is being dynamically loaded from Firebase Cloud Storage and cached.',
          fontFamily: firaCode,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: ExtendedButton(
        icon: Icons.navigate_next,
        label: 'Next Example',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<DynamicCachedFontsDemo5>(
            builder: (_) => const DynamicCachedFontsDemo5(),
          ),
        ),
      ),
    );
  }
}
