import 'package:dynamic_cached_fonts/dynamic_cached_fonts.dart';
import 'package:dynamic_cached_fonts_example/constants.dart';
import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart' show IntegrationTestWidgetsFlutterBinding;

const String fontUrl = cascadiaCodeUrl,
    fontName = cascadiaCode,
    firebaseFontUrl = firaCodeUrl,
    firebaseFontName = firaCode;

final String cacheKey = cacheKeyFromUrl(fontUrl);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  CacheManager cacheManager;

  setUpAll(() {
    cacheManager = CacheManager(Config(cacheKey));

    DynamicCachedFonts.custom(cacheManager: cacheManager);
  });

  group('DynamicCachedFonts.load', () {
    FileInfo fontFile;
    DynamicCachedFonts fontLoader;

    setUpAll(() async {
      fontLoader = DynamicCachedFonts(url: fontUrl, fontFamily: fontName);

      await fontLoader.load();

      fontFile = await cacheManager.getFileFromCache(cacheKey);
    });

    testWidgets('Font file is loaded into cache', (_) async {
      expect(fontFile, isNotNull);
    });

    testWidgets('Loaded font file has a valid extension', (_) async {
      final String fontExtension = fontFile.file.uri.pathSegments.last.split('.').last;

      expect(fontExtension, 'ttf');
    });

    testWidgets('Font can be loaded only once', (_) async {
      expect(fontLoader.load(), throwsStateError);
    });

    testWidgets('Font loader loads valid font file', (_) async {
      final FileInfo downloadedFontFile = await cacheManager.downloadFile(
        fontUrl,
        key: '$cacheKey-test',
      );

      expect(
        downloadedFontFile.file.readAsBytesSync(),
        fontFile.file.readAsBytesSync(),
      );
    });
  });

  testWidgets('DynamicCachedFonts.family loads all fonts into cache', (_) async {
    const List<String> fontUrls = <String>[
      firaSansBoldUrl,
      firaSansItalicUrl,
      firaSansRegularUrl,
      firaSansThinUrl,
    ];

    await DynamicCachedFonts.family(
      urls: fontUrls,
      fontFamily: firaSans,
    ).load();

    final List<FileInfo> fontFiles = await Future.wait(fontUrls.map(
      (String url) async {
        final String generatedCacheKey = cacheKeyFromUrl(url);

        return cacheManager.getFileFromCache(generatedCacheKey);
      },
    ));

    expect(fontFiles.every((FileInfo file) => file != null), isTrue);
  });

  group('DynamicCachedFonts.fromFirebase', () {
    FileInfo fontFile;
    Reference bucketRef;

    setUpAll(() async {
      await Firebase.initializeApp();

      await DynamicCachedFonts.fromFirebase(
        bucketUrl: firebaseFontUrl,
        fontFamily: firebaseFontName,
      ).load();

      bucketRef = FirebaseStorage.instance.refFromURL(firebaseFontUrl);

      final String cacheKey = cacheKeyFromUrl(await bucketRef.getDownloadURL());

      fontFile = await cacheManager.getFileFromCache(cacheKey);
    });

    testWidgets('load() method parses Firebase Bucket Url and loads font', (_) async {
      expect(fontFile, isNotNull);
    });

    testWidgets('Font loader loads valid font file from Firebase', (_) async {
      expect(
        fontFile.file.readAsBytesSync(),
        await bucketRef.getData(),
      );
    });
  });

  group('DynamicCachedFonts.cacheFont', () {
    FileInfo fontFile;

    setUpAll(() async {
      DynamicCachedFonts.cacheFont(fontUrl);

      fontFile = await cacheManager.getFileFromCache(cacheKey);
    });

    testWidgets('DynamicCachedFonts.cacheFont loads font into cache', (_) async {
      expect(fontFile, isNotNull);
    });

    testWidgets('DynamicCachedFonts.cacheFont loads font with a valid extension', (_) async {
      final String fontExtension = fontFile.file.uri.pathSegments.last.split('.').last;

      expect(fontExtension, 'ttf');
    });

    testWidgets('throws UnsupportedError if file extension is not valid', (_) async {
      const String woffUrl =
          'https://cdn.jsdelivr.net/gh/mozilla/Fira@4.202/woff/FiraMono-Regular.woff';

      expect(DynamicCachedFonts.cacheFont(woffUrl), throwsUnsupportedError);
    });
  });

  group('DynamicCachedFonts.canLoadFont', () {
    testWidgets('DynamicCachedFonts.canLoadFont returns true when font is available in cache',
        (_) async {
      await cacheManager.downloadFile(
        fontUrl,
        key: cacheKey,
      );

      expect(
        await DynamicCachedFonts.canLoadFont(fontUrl),
        true,
      );
    });

    testWidgets('DynamicCachedFonts.canLoadFont returns false when font is not available in cache',
        (_) async {
      await cacheManager.removeFile(cacheKey);

      // Temporary hack for file removal
      Future<void>.delayed(
        const Duration(seconds: 10),
        () async => expect(
          await DynamicCachedFonts.canLoadFont(fontUrl),
          false,
        ),
      );
    });
  });

  group('DynamicCachedFonts.loadCachedFont', () {
    FileInfo downloadedFontFile;
    FileInfo fontFile;
    FontLoader fontLoader;

    setUpAll(() async {
      downloadedFontFile = await cacheManager.downloadFile(fontUrl, key: cacheKey);

      fontLoader = FontLoader(fontName);

      fontFile = await DynamicCachedFonts.loadCachedFont(
        fontUrl,
        fontFamily: fontName,
        fontLoader: fontLoader,
      );
    });

    testWidgets('loads font into cache', (_) async {
      expect(fontFile, isNotNull);
    });

    testWidgets('loads valid font file', (_) async {
      expect(
        downloadedFontFile.file.readAsBytesSync(),
        fontFile.file.readAsBytesSync(),
      );
    });

    testWidgets('loads font into the Flutter Engine', (_) async {
      // This tests that load() is being called in loadCachedFamily.
      // A single instance of FontLoader can only be loaded once, so if
      // StateError is thrown, it means that load() has already been called.
      expect(fontLoader.load(), throwsStateError);
    });
  });

  group('DynamicCachedFonts.loadCachedFamily', () {
    Iterable<FileInfo> fontFiles;
    List<FileInfo> downloadedFontFiles;
    FontLoader fontLoader;

    const List<String> fontUrls = <String>[
      firaSansBoldUrl,
      firaSansItalicUrl,
      firaSansRegularUrl,
      firaSansThinUrl,
    ];

    setUpAll(() async {
      downloadedFontFiles = await Future.wait(fontUrls.map(
        (String url) async {
          final String generatedCacheKey = cacheKeyFromUrl(url);

          return cacheManager.downloadFile(url, key: generatedCacheKey);
        },
      ));

      fontLoader = FontLoader(fontName);

      fontFiles = await DynamicCachedFonts.loadCachedFamily(
        fontUrls,
        fontFamily: firaSans,
        fontLoader: fontLoader,
      );
    });

    testWidgets('loads font into cache', (_) async {
      expect(fontFiles.every((FileInfo file) => file != null), isTrue);
    });

    testWidgets('loads valid font files', (_) async {
      for (final FileInfo font in fontFiles) {
        final FileInfo downloadedFont = downloadedFontFiles[fontFiles.toList().indexOf(font)];
        expect(font.file.readAsBytesSync(), downloadedFont.file.readAsBytesSync());
      }
    });

    testWidgets('loads font into the Flutter Engine', (_) async {
      // This tests that load() is being called in loadCachedFamily.
      // A single instance of FontLoader can only be loaded once, so if
      // StateError is thrown, it means that load() has already been called.
      expect(fontLoader.load(), throwsStateError);
    });
  });

  testWidgets('DynamicCachedFonts.removeCachedFont removes the font from cache', (_) async {
    await cacheManager.downloadFile(fontUrl, key: cacheKey);

    expect(
      await cacheManager.getFileFromCache(cacheKey),
      isNotNull,
    );

    await DynamicCachedFonts.removeCachedFont(fontUrl);

    // Temporary hack for file removal
    Future<void>.delayed(
      const Duration(seconds: 10),
      () async => expect(
        await cacheManager.getFileFromCache(cacheKey),
        isNull,
      ),
    );
  });
}
