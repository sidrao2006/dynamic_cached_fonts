import 'dart:typed_data';

import 'package:dynamic_cached_fonts/dynamic_cached_fonts.dart';
import 'package:dynamic_cached_fonts_example/constants.dart';
import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
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

    testWidgets('should load font into cache', (_) async {
      expect(font, isNotNull);
    });

    testWidgets('should load font file with a valid extension', (_) async {
      final String fontFileName = font.file.basename;

      expect(fontFileName, endsWith('ttf'));
    });

    testWidgets('should allow font to be loaded only once', (_) async {
      expect(cachedFontLoader.load(), throwsStateError);
    });

    testWidgets('should load valid font file', (_) async {
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

  group('DynamicCachedFonts.family', () {
    Iterable<FileInfo> fonts;
    DynamicCachedFonts cachedFontLoader;

    const List<String> fontUrls = <String>[
      firaSansBoldUrl,
      firaSansItalicUrl,
      firaSansRegularUrl,
      firaSansThinUrl,
    ];

    setUp(() async {
      cachedFontLoader = DynamicCachedFonts.family(
        urls: fontUrls,
        fontFamily: firaSans,
      );

      fonts = await cachedFontLoader.load();
    });

    testWidgets('should load all fonts into cache', (_) async {
      expect(fonts, everyElement(isNotNull));
    });

    testWidgets('should load valid font files', (_) async {
      final List<Uint8List> downloadedFontBytes = await awaitedMap(fontUrls, (String url) async {
        final String generatedCacheKey = cacheKeyFromUrl(url);
        final FileInfo donwloadedFont =
            await cacheManager.downloadFile(url, key: '$generatedCacheKey-test');

        return donwloadedFont.file.readAsBytes();
      });

      final List<Uint8List> fontBytes =
          fonts.map((FileInfo font) => font.file.readAsBytesSync()).toList();

      for (int i = 0; i < fontUrls.length; i++) {
        expect(fontBytes[i], orderedEquals(downloadedFontBytes[i]));
      }
    });

    testWidgets('should load the font family into the Flutter Engine', (_) async {
      expect(cachedFontLoader.load(), throwsStateError);
    });
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

    testWidgets('should parse Firebase Bucket URL', (_) async {
      expect(font.originalUrl, equals(await bucketRef.getDownloadURL()));
    });

    testWidgets('should load font into cache', (_) async {
      expect(font, isNotNull);
    });

    testWidgets('should load valid font file from Firebase', (_) async {
      expect(
        font.file.readAsBytesSync(),
        orderedEquals(await bucketRef.getData()),
      );
    });
  },
      skip: ThemeData().platform == TargetPlatform.windows ||
          ThemeData().platform == TargetPlatform.linux);

  group('DynamicCachedFonts.cacheFont', () {
    FileInfo font;

    setUp(() async {
      await DynamicCachedFonts.cacheFont(fontUrl);

      font = await cacheManager.getFileFromCache(cacheKey);
    });

    testWidgets('should load font into cache', (_) async {
      expect(font, isNotNull);
    });

    testWidgets('should load font file with a valid extension', (_) async {
      final String fontFileName = font.file.basename;

      expect(fontFileName, endsWith('ttf'));
    });

    testWidgets('should throw UnsupportedError if file extension is not valid', (_) async {
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

    testWidgets('should return true when font is available in cache', (_) async {
      expect(
        await DynamicCachedFonts.canLoadFont(fontUrl),
        isTrue,
      );
    });

    testWidgets('should return false when font is not available in cache', (_) async {
      await cacheManager.removeFile(cacheKey);

      // Temporary hack for file removal
      Future<void>.delayed(
        const Duration(milliseconds: 10),
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

    testWidgets('should load font into cache', (_) async {
      expect(font, isNotNull);
    });

    testWidgets('should load valid font file', (_) async {
      expect(
        downloadedFont.file.readAsBytesSync(),
        orderedEquals(font.file.readAsBytesSync()),
      );
    });

    testWidgets('should load font into the Flutter Engine', (_) async {
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

    testWidgets('should load all fonts into cache', (_) async {
      expect(fonts, everyElement(isNotNull));
    });

    testWidgets('should load valid font files', (_) async {
      final List<Uint8List> downloadedFontBytes = downloadedFonts
          .map((FileInfo downloadedFont) => downloadedFont.file.readAsBytesSync())
          .toList();

      final List<Uint8List> fontBytes =
          fonts.map((FileInfo font) => font.file.readAsBytesSync()).toList();

      for (int i = 0; i < fontUrls.length; i++) {
        expect(fontBytes[i], orderedEquals(downloadedFontBytes[i]));
      }
    });

    testWidgets('should load the font family into the Flutter Engine', (_) async {
      // This tests that load() is being called in loadCachedFamily.
      // A single instance of FontLoader can only be loaded once, so if
      // StateError is thrown, it means that load() has already been called.
      expect(fontLoader.load(), throwsStateError);
    });
  });

  testWidgets('DynamicCachedFonts.removeCachedFont should remove the font from cache', (_) async {
    await cacheManager.downloadFile(fontUrl, key: cacheKey);

    await DynamicCachedFonts.removeCachedFont(fontUrl);

    // Temporary hack for file removal
    Future<void>.delayed(
      const Duration(milliseconds: 10),
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
