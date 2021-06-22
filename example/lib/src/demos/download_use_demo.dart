import 'package:dynamic_cached_fonts/dynamic_cached_fonts.dart';
import 'package:dynamic_cached_fonts_example/constants.dart';
import 'package:flutter/material.dart';

import '../components.dart';
import 'download_use_delete_demo.dart';

class DynamicCachedFontsDemo2 extends StatelessWidget {
  const DynamicCachedFontsDemo2({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('$demoTitle - Load on Demand'),
      ),
      body: Column(
        children: <Widget>[
          CustomButton(
            title: 'Download and Use',
            onPressed: handleDownloadButtonPress,
          ),
          Expanded(
            child: DisplayText(
              'The text is being displayed in the default flutter font which is ${DefaultTextStyle.of(context).style.fontFamily}. To load this text in $firaMono, click the download button above ☝️',
              fontFamily: firaMono,
            ),
          ),
        ],
      ),
      floatingActionButton: ExtendedButton(
        icon: Icons.navigate_next,
        label: 'Next Example',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<DynamicCachedFontsDemo3>(
            builder: (_) => const DynamicCachedFontsDemo3(),
          ),
        ),
      ),
    );
  }

  void handleDownloadButtonPress() {
    final DynamicCachedFonts dynamicCachedFont = DynamicCachedFonts(
      fontFamily: firaMono,
      url: firaMonoUrl,
    );

    dynamicCachedFont.load();
  }
}
