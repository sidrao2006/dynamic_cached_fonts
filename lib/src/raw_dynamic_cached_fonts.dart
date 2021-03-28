import 'dart:typed_data' show ByteData, Uint8List;

import 'package:flutter/foundation.dart' show kReleaseMode, required, FlutterError;
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter/widgets.dart' show WidgetsFlutterBinding, TextStyle;
import 'package:flutter_cache_manager/flutter_cache_manager.dart'
    show CacheManager, Config, FileInfo;

import 'utils.dart';

/// A more customizable implementation of [DynamicCachedFonts] which uses
/// multiple static methods to download, cache, load and remove font assets.
///
/// [DynamicCachedFonts] is a concrete implementation of this class.
abstract class RawDynamicCachedFonts {
  /// Caches the [url] with the given configuration.
  ///
  /// - **REQUIRED** The [url] property is used to specify the download url
  ///   for the required font. It should be a valid http/https url which points to
  ///   a font file.
  ///   Currently, only OpenType (OTF) and TrueType (TTF) fonts are supported.
  ///
  /// - The [maxCacheObjects] property defines how large the cache is allowed to be.
  ///   If there are more files the files that haven't been used for the longest
  ///   time will be removed.
  ///
  ///   It is used to specify the cache configuration, [Config],
  ///   for [CacheManager].
  ///
  /// - [cacheStalePeriod] is the time duration in which
  ///   a cache object is considered 'stale'. When a file is cached but
  ///   not being used for a certain time the file will be deleted
  ///
  ///   It is used to specify the cache configuration, [Config],
  ///   for [CacheManager].
  ///
  /// - The [verboseLog] is a debug property used to specify whether detailed
  ///   logs should be printed for debugging.
  ///
  ///   Defaults to false.
  ///
  ///   _Tip: To log only in debug mode, set [verboseLog]'s value to [kReleaseMode]_.
  static Future<void> cacheFont(
    String url, {
    @required int maxCacheObjects,
    @required Duration cacheStalePeriod,
    bool verboseLog = false,
  }) async {
    assert(verboseLog != null);

    WidgetsFlutterBinding.ensureInitialized();

    if (!Utils.verifyFileFormat(url)) {
      throw FlutterError(
        'Invalid url. Unsupported file format. Supported file formats - otf and ttf',
      );
    }
    final String cacheKey = Utils.sanitizeUrl(url);

    final Config cacheconfig = Config(
      cacheKey,
      stalePeriod: cacheStalePeriod,
      maxNrOfCacheObjects: maxCacheObjects,
    );
    final FileInfo font = await CacheManager(cacheconfig).downloadFile(
      url,
      key: cacheKey,
    );

    devLog(
      <String>[
        "Font file downloaded\n",
        "Validity: ${font.validTill}",
        "Download URL: ${font.originalUrl}",
      ],
      verboseLog: verboseLog,
    );
  }

  /// Checks whether the given [url] can be loaded directly from cache.
  ///
  /// - **REQUIRED** The [url] property is used to specify the url
  ///   for the required font. It should be a valid http/https url which points to
  ///   a font file. The [url] should match the url passed to [cacheFont].
  ///
  /// - The [verboseLog] is a debug property used to specify whether detailed
  ///   logs should be printed for debugging.
  ///
  ///   Defaults to false.
  ///
  ///   _Tip: To log only in debug mode, set [verboseLog]'s value to [kReleaseMode]_.
  static Future<bool> canLoadFont(
    String url, {
    bool verboseLog = false,
  }) async {
    assert(verboseLog != null);

    WidgetsFlutterBinding.ensureInitialized();

    final String cacheKey = Utils.sanitizeUrl(url);

    FileInfo font;

    // Try catch to catch any errors thrown by the cache manager
    // or the assertion.
    try {
      font = await CacheManager(Config(cacheKey)).getFileFromCache(cacheKey);

      assert(
        font != null,
        <String>[
          'Font is not available in cache.',
          'Call cacheFont to download font.',
        ].join(),
      );
    } catch (e) {
      devLog(
        <String>[e.toString()],
        verboseLog: verboseLog,
      );
    }
    return font != null;
  }

  /// Fetches the given [url] from cache and loads it as an asset.
  ///
  /// Call [canLoadFont] before calling this method to make sure the font is
  /// available in cache.
  ///
  /// - **REQUIRED** The [url] property is used to specify the url
  ///   for the required font. It should be a valid http/https url which points to
  ///   a font file. The [url] should match the url passed to [cacheFont].
  ///
  /// - **REQUIRED** The [fontFamily] property is used to specify the name
  ///   of the font family which is to be used as [TextStyle.fontFamily].
  ///
  /// - The [verboseLog] is a debug property used to specify whether detailed
  ///   logs should be printed for debugging.
  ///
  ///   Defaults to false.
  ///
  ///   _Tip: To log only in debug mode, set [verboseLog]'s value to [kReleaseMode]_.
  static Future<void> loadCachedFont(
    String url, {
    @required String fontFamily,
    bool verboseLog = false,
  }) async {
    assert(verboseLog != null);

    WidgetsFlutterBinding.ensureInitialized();

    final String cacheKey = Utils.sanitizeUrl(url);

    final FileInfo font = await CacheManager(Config(cacheKey)).getFileFromCache(cacheKey);

    final Uint8List fontBytes = await font.file.readAsBytes();

    final ByteData cachedFontBytes = ByteData.view(fontBytes.buffer);

    final FontLoader fontLoader = FontLoader(fontFamily)
      ..addFont(
        Future<ByteData>.value(cachedFontBytes),
      );

    await fontLoader.load();

    devLog(
      <String>['Font has been loaded!'],
      verboseLog: verboseLog,
    );
  }

  /// Fetches the given [urls] from cache and loads them into the engine to be used.
  ///
  /// [urls] should be a series of related font assets,
  /// each of which defines how to render a specific [FontWeight] and [FontStyle]
  /// within the family.
  ///
  /// Call [canLoadFont] before calling this method to make sure the font is
  /// available in cache.
  ///
  /// - **REQUIRED** The [urls] property is used to specify the urls
  ///   for the required family. It should be a list of valid http/https urls
  ///   which point to font files.
  ///   Every url in [urls] should be loaded into cache by calling [cacheFont] for each.
  ///
  /// - **REQUIRED** The [fontFamily] property is used to specify the name
  ///   of the font family which is to be used as [TextStyle.fontFamily].
  ///
  /// - The [verboseLog] is a debug property used to specify whether detailed
  ///   logs should be printed for debugging.
  ///
  ///   Defaults to false.
  ///
  ///   _Tip: To log only in debug mode, set [verboseLog]'s value to [kReleaseMode]_.
  static Future<void> loadCachedFamily(
    List<String> urls, {
    @required String fontFamily,
    bool verboseLog = false,
  }) async {
    assert(verboseLog != null);

    WidgetsFlutterBinding.ensureInitialized();

    final Iterable<Future<ByteData>> cachedFontBytes = urls.map((String url) async {
      final String cacheKey = Utils.sanitizeUrl(url);

      final FileInfo font = await CacheManager(Config(cacheKey)).getFileFromCache(cacheKey);

      final Uint8List fontBytes = await font.file.readAsBytes();

      return ByteData.view(fontBytes.buffer);
    });

    final FontLoader fontLoader = FontLoader(fontFamily);

    for (final Future<ByteData> bytes in cachedFontBytes) fontLoader.addFont(bytes);

    await fontLoader.load();

    devLog(
      <String>['Font has been loaded!'],
      verboseLog: verboseLog,
    );
  }

  /// Removes the given [url] can be loaded directly from cache.
  ///
  /// Call [canLoadFont] before calling this method to make sure the font is
  /// available in cache.
  ///
  /// - **REQUIRED** The [url] property is used to specify the url
  ///   for the required font. It should be a valid http/https url which points to
  ///   a font file. The [url] should match the url passed to [cacheFont].
  static Future<void> removeCachedFont(String url) async {
    WidgetsFlutterBinding.ensureInitialized();

    final String cacheKey = Utils.sanitizeUrl(url);

    return CacheManager(Config(cacheKey)).removeFile(cacheKey);
  }
}
