import 'package:dynamic_cached_fonts/dynamic_cached_fonts.dart';
import 'package:flutter/material.dart';
import 'package:dynamic_cached_fonts_example/constants.dart';

import '../components.dart';
import 'download_use_controls_family_stream_demo.dart';

class DynamicCachedFontsDemo6 extends StatefulWidget {
  const DynamicCachedFontsDemo6({Key? key}) : super(key: key);

  @override
  _DynamicCachedFontsDemo6State createState() => _DynamicCachedFontsDemo6State();
}

class _DynamicCachedFontsDemo6State extends State<DynamicCachedFontsDemo6> {
  int position = 0, total = 0;
  double progress = 0;

  late final Stream<FileInfo> fontStream;
  DownloadProgress? downloadProgress;

  @override
  void initState() {
    setupFontLoader();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '$demoTitle - Load Family As Stream',
        ),
      ),
      body: Column(
        children: <Widget>[
          CustomButton(
            title: 'Download and Use',
            onPressed: handleDownloadButtonPress,
          ),
          DisplayText(
            'The text is being displayed in the default flutter font which is ${DefaultTextStyle.of(context).style.fontFamily}.',
            fontFamily: '',
            fontSize: Theme.of(context).textTheme.headline6!.fontSize,
          ),
          DisplayText(
            'To download $roboto bold, click the download button above ☝️.',
            fontFamily: roboto,
            fontWeight: FontWeight.bold,
            fontSize: Theme.of(context).textTheme.headline6!.fontSize,
          ),
          DisplayText(
            'To download $roboto italic, click the download button above ☝️.',
            fontFamily: roboto,
            fontStyle: FontStyle.italic,
            fontSize: Theme.of(context).textTheme.headline6!.fontSize,
          ),
          DisplayText(
            'To download $roboto, click the download button above ☝️.',
            fontFamily: roboto,
            fontSize: Theme.of(context).textTheme.headline6!.fontSize,
          ),
          DisplayText(
            'To download $roboto thin, click the download button above ☝️.',
            fontFamily: roboto,
            fontWeight: FontWeight.w100,
            fontSize: Theme.of(context).textTheme.headline6!.fontSize,
          ),
          ...showLoaders(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: ExtendedButton(
        icon: Icons.navigate_next,
        label: 'Next Example',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<DynamicCachedFontsDemo7>(
            builder: (_) => const DynamicCachedFontsDemo7(),
          ),
        ),
      ),
    );
  }

  void handleDownloadButtonPress() => fontStream.listen((_) {});

  void setupFontLoader() {
    final DynamicCachedFonts dynamicCachedFont = DynamicCachedFonts.family(
      fontFamily: roboto,
      urls: [robotoBoldUrl, robotoItalicUrl, robotoRegularUrl, robotoThinUrl],
    );
    fontStream = dynamicCachedFont.loadStream(
      itemCountProgressListener: (progress, totalItems, currentFont) => setState(() {
        this.progress = progress;
        total = totalItems;
        position = currentFont;
      }),
      downloadProgressListener: (downloadProgress) =>
          setState(() => this.downloadProgress = downloadProgress),
    );
  }

  List<Widget> showLoaders() {
    final List<Widget> loaders = [];

    if (position != total)
      loaders.addAll([
        Text('Downloading font $position of $total...'),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: LinearProgressIndicator(
            value: progress,
          ),
        )
      ]);
    else if (position == total && position != 0)
      loaders.add(Text('Download complete! $total fonts downloaded.'));

    if (downloadProgress != null && downloadProgress!.progress != null)
      loaders.addAll([
        Text('Downloading font from ${downloadProgress?.originalUrl}...'),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: LinearProgressIndicator(
            value: downloadProgress?.progress ?? 0,
          ),
        ),
      ]);
    else if (downloadProgress != null && downloadProgress!.downloaded > 0)
      loaders.add(Text('Downloaded font from ${downloadProgress?.originalUrl}!'));

    return loaders;
  }
}
