import 'package:async/async.dart' show StreamGroup;

import 'package:dynamic_cached_fonts/dynamic_cached_fonts.dart';
import 'package:dynamic_cached_fonts_example/constants.dart';
import 'package:flutter/material.dart';

import '../components.dart';

class DynamicCachedFontsDemo7 extends StatefulWidget {
  const DynamicCachedFontsDemo7({Key? key}) : super(key: key);

  @override
  _DynamicCachedFontsDemo7State createState() => _DynamicCachedFontsDemo7State();
}

class _DynamicCachedFontsDemo7State extends State<DynamicCachedFontsDemo7> {
  int position = 0, total = 0;
  double progress = 0;
  DownloadProgress? downloadProgress;

  final List<String> fontUrls = [mononokiBoldUrl, mononokiItalicUrl, mononokiRegularUrl];
  late final Stream<FileInfo> downloadFontStreams;
  late final Stream<FileInfo> loadCachedFamilyStream;

  @override
  void initState() {
    setupFontLoader();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('$demoTitle - Load Family As Stream (Custom Controls)'),
      ),
      body: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <CustomButton>[
              CustomButton(
                onPressed: handleDownloadButtonPress,
              ),
              CustomButton(
                icon: Icons.font_download,
                title: 'Use Font',
                onPressed: handleUseFontPress,
              ),
            ],
          ),
          DisplayText(
            'The text is being displayed in the default flutter font which is ${DefaultTextStyle.of(context).style.fontFamily}.',
            fontFamily: '',
            fontSize: Theme.of(context).textTheme.headline6!.fontSize,
          ),
          DisplayText(
            'To download $mononoki bold, click the download button above ☝️.',
            fontFamily: mononoki,
            fontWeight: FontWeight.bold,
            fontSize: Theme.of(context).textTheme.headline6!.fontSize,
          ),
          DisplayText(
            'To download $mononoki italic, click the download button above ☝️.',
            fontFamily: mononoki,
            fontStyle: FontStyle.italic,
            fontSize: Theme.of(context).textTheme.headline6!.fontSize,
          ),
          DisplayText(
            'To download $mononoki, click the download button above ☝️.',
            fontFamily: mononoki,
            fontSize: Theme.of(context).textTheme.headline6!.fontSize,
          ),
          ...showLoaders()
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: ExtendedButton(
        icon: Icons.navigate_before,
        label: 'Previous Example',
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> handleDownloadButtonPress() => downloadFontStreams.listen((_) {}).asFuture();

  Future<void> handleUseFontPress() async {
    if ((await Future.wait(fontUrls.map(DynamicCachedFonts.canLoadFont)))
        .every((canLoad) => canLoad = true))
      loadCachedFamilyStream.listen((_) {});
    else {
      print('Font not found in cache :(');
      // Font is not in cache...download font or do something else.

      // Uncomment the below line to download font is it is not present in cache.
      // return await DynamicCachedFonts.cacheFont(url);
    }
  }

  void setupFontLoader() {
    downloadFontStreams = StreamGroup.merge(
      fontUrls.map(
        (url) => DynamicCachedFonts.cacheFontStream(
          url,
          progressListener: (downloadProgress) =>
              setState(() => this.downloadProgress = downloadProgress),
        ),
      ),
    );

    loadCachedFamilyStream = DynamicCachedFonts.loadCachedFamilyStream(
      fontUrls,
      fontFamily: mononoki,
      progressListener: (progress, totalItems, currentFont) => setState(() {
        this.progress = progress;
        total = totalItems;
        position = currentFont;
      }),
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
