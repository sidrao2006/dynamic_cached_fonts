import 'dart:typed_data';

import 'package:dynamic_cached_fonts/dynamic_cached_fonts.dart';
import 'package:dynamic_cached_fonts_example/constants.dart';
import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart' show FontLoader;
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

  tearDown(() => cacheManager.emptyCache());

  group('DynamicCachedFonts.load', () {
    FileInfo font;
    DynamicCachedFonts cachedFontLoader;

    setUp(() async {
      cachedFontLoader = DynamicCachedFonts(url: fontUrl, fontFamily: fontName);

      font = (await cachedFontLoader.load()).first;
    });

    testWidgets('Font file is loaded into cache', (_) async {
      expect(font, isNotNull);
    });

    testWidgets('Loaded font file has a valid extension', (_) async {
      final String fontFileName = font.file.basename;

      expect(fontFileName, endsWith('ttf'));
    });

    testWidgets('Font can be loaded only once', (_) async {
      expect(cachedFontLoader.load(), throwsStateError);
    });

    testWidgets('Font loader loads valid font file', (_) async {
      final FileInfo downloadedFont = await cacheManager.downloadFile(
        fontUrl,
        key: '$cacheKey-test',
      );

      expect(
        downloadedFont.file.readAsBytesSync(),
        orderedEquals(font.file.readAsBytesSync()),
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

    final Iterable<FileInfo> fonts = await DynamicCachedFonts.family(
      urls: fontUrls,
      fontFamily: firaSans,
    ).load();

    expect(fonts, everyElement(isNotNull));
  });

  group('DynamicCachedFonts.fromFirebase', () {
    FileInfo font;
    Reference bucketRef;

    setUp(() async {
      await Firebase.initializeApp();

      font = (await DynamicCachedFonts.fromFirebase(
        bucketUrl: firebaseFontUrl,
        fontFamily: firebaseFontName,
      ).load())
          .first;

      bucketRef = FirebaseStorage.instance.refFromURL(firebaseFontUrl);
    });

    testWidgets('parses Firebase Bucket URL', (_) async {
      expect(font.originalUrl, equals(await bucketRef.getDownloadURL()));
    });

    testWidgets('load() method parses Firebase Bucket Url and loads font', (_) async {
      expect(font, isNotNull);
    });

    testWidgets('Font loader loads valid font file from Firebase', (_) async {
      expect(
        font.file.readAsBytesSync(),
        orderedEquals(await bucketRef.getData()),
      );
    });
  });

  group('DynamicCachedFonts.cacheFont', () {
    FileInfo font;

    setUp(() async {
      await DynamicCachedFonts.cacheFont(fontUrl);

      font = await cacheManager.getFileFromCache(cacheKey);
    });

    testWidgets('DynamicCachedFonts.cacheFont loads font into cache', (_) async {
      expect(font, isNotNull);
    });

    testWidgets('DynamicCachedFonts.cacheFont loads font with a valid extension', (_) async {
      final String fontFileName = font.file.basename;

      expect(fontFileName, endsWith('ttf'));
    });

    testWidgets('throws UnsupportedError if file extension is not valid', (_) async {
      const String woffUrl =
          'https://cdn.jsdelivr.net/gh/mozilla/Fira@4.202/woff/FiraMono-Regular.woff';

      expect(DynamicCachedFonts.cacheFont(woffUrl), throwsUnsupportedError);
    });
  });

  group('DynamicCachedFonts.canLoadFont', () {
    setUp(() => cacheManager.downloadFile(
          fontUrl,
          key: cacheKey,
        ));

    testWidgets('DynamicCachedFonts.canLoadFont returns true when font is available in cache',
        (_) async {
      expect(
        await DynamicCachedFonts.canLoadFont(fontUrl),
        isTrue,
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
          isFalse,
        ),
      );
    });
  });

  group('DynamicCachedFonts.loadCachedFont', () {
    FontLoader fontLoader;
    FileInfo font;
    FileInfo downloadedFont;

    setUp(() async {
      fontLoader = FontLoader(fontName);

      downloadedFont = await cacheManager.downloadFile(fontUrl, key: cacheKey);

      font = await DynamicCachedFonts.loadCachedFont(
        fontUrl,
        fontFamily: fontName,
        fontLoader: fontLoader,
      );
    });

    testWidgets('loads font into cache', (_) async {
      expect(font, isNotNull);
    });

    testWidgets('loads valid font file', (_) async {
      expect(
        downloadedFont.file.readAsBytesSync(),
        orderedEquals(font.file.readAsBytesSync()),
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
    FontLoader fontLoader;
    Iterable<FileInfo> fonts;
    Iterable<FileInfo> downloadedFonts;

    const List<String> fontUrls = <String>[
      firaSansBoldUrl,
      firaSansItalicUrl,
      firaSansRegularUrl,
      firaSansThinUrl,
    ];

    setUp(() async {
      fontLoader = FontLoader(fontName);

      downloadedFonts = await awaitedMap(fontUrls, (String url) {
        final String generatedCacheKey = cacheKeyFromUrl(url);
        return cacheManager.downloadFile(url, key: generatedCacheKey);
      });

      fonts = await DynamicCachedFonts.loadCachedFamily(
        fontUrls,
        fontFamily: firaSans,
        fontLoader: fontLoader,
      );
    });

    testWidgets('loads font into cache', (_) async {
      expect(fonts, everyElement(isNotNull));
    });

    testWidgets('loads valid font files', (_) async {
      final List<Uint8List> downloadedFontBytes = downloadedFonts
          .map((FileInfo downloadedFont) => downloadedFont.file.readAsBytesSync())
          .toList();

      final List<Uint8List> fontBytes =
          fonts.map((FileInfo font) => font.file.readAsBytesSync()).toList();

      for (int i = 0; i < fontUrls.length; i++) {
        expect(fontBytes[i], orderedEquals(downloadedFontBytes[i]));
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

// Helpers

Future<List<T>> awaitedMap<T, E>(
  Iterable<E> iterable,
  Future<T> Function(E) f,
) =>
    Future.wait(iterable.map(f));
