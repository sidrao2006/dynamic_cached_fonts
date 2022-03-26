part of dynamic_cached_fonts;

/// A more customizable implementation of [DynamicCachedFonts] which uses
/// multiple static methods to download, cache, load and remove font assets.
///
/// [DynamicCachedFonts] is a concrete implementation of this class.
abstract class RawDynamicCachedFonts {
  const RawDynamicCachedFonts._();

  /// Accepts [cacheManager] and [force] to provide a custom [CacheManager] for testing.
  ///
  /// - **REQUIRED** The [cacheManager] property is used to specify a custom instance of
  ///   [CacheManager]. Caching can be customized using the [Config] object passed to
  ///   the instance.
  ///
  /// - The [force] property is used to specify whether or not to overwrite an existing
  ///   instance of custom cache manager.
  ///
  ///   If [force] is true and a custom cache manager already exists, it will be
  ///   overwritten with the new instance. This means any fonts cached earlier,
  ///   cannot be accessed using the new instance.
  /// ---
  /// Any new [DynamicCachedFonts] instance or any [RawDynamicCachedFonts] methods
  /// called after this method will use [cacheManager] to download, cache
  /// and load fonts. This means custom configuration **cannot** be provided.
  ///
  /// `maxCacheObjects` and `cacheStalePeriod` in [cacheFont] will have no effect
  /// after calling this method. Customize these values in the [Config] object
  /// passed to the [CacheManager] used in [cacheManager].
  @visibleForTesting
  static void custom({
    required CacheManager cacheManager,
    bool force = false,
  }) {
    if (force)
      DynamicCachedFontsCacheManager.setCustomCacheManager(cacheManager);
    else if (DynamicCachedFontsCacheManager.getCustomCacheManager() == null)
      DynamicCachedFontsCacheManager.setCustomCacheManager(cacheManager);
  }

  /// Downloads and caches font from the [url] with the given configuration.
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
  static Future<FileInfo> cacheFont(
    String url, {
    required int maxCacheObjects,
    required Duration cacheStalePeriod,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();

    final String cacheKey = Utils.sanitizeUrl(url);

    DynamicCachedFontsCacheManager.handleCacheManager(cacheKey, cacheStalePeriod, maxCacheObjects);

    final FileInfo font =
        await DynamicCachedFontsCacheManager.getCacheManager(cacheKey).downloadFile(
      url,
      key: cacheKey,
    );

    Utils.verifyFileExtension(font.file);

    devLog(<String>[
      'Font file downloaded\n',
      'Validity: ${font.validTill}',
      'Download URL: ${font.originalUrl}',
    ]);

    return font;
  }

  /// Downloads and caches font from the [url] with the given configuration.
  /// A single [FileInfo] object is returned as a stream and the download
  /// progress is can be listened to using the [progressListener] callback.
  ///
  /// If this method is called multiple times for the same font [url], then the
  /// cached file is returned with no progress events being emitted to the
  /// [progressListener] callback.
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
  /// - The [progressListener] property is used to listen to the download progress
  ///   of the font. It is called with a [DownloadProgress] object which contains
  ///   information about the download progress.
  static Stream<FileInfo> cacheFontStream(
    String url, {
    required int maxCacheObjects,
    required Duration cacheStalePeriod,
    required DownloadProgressListener? progressListener,
  }) async* {
    WidgetsFlutterBinding.ensureInitialized();

    final String cacheKey = Utils.sanitizeUrl(url);

    DynamicCachedFontsCacheManager.handleCacheManager(cacheKey, cacheStalePeriod, maxCacheObjects);

    final Stream<FileResponse> stream =
        DynamicCachedFontsCacheManager.getCacheManager(cacheKey).getFileStream(
      url,
      key: cacheKey,
      withProgress: progressListener != null,
    );

    await for (final result in stream) {
      if (result is FileInfo) {
        Utils.verifyFileExtension(result.file);

        devLog([
          'Font file downloaded\n',
          'Validity: ${result.validTill}',
          'Download URL: ${result.originalUrl}',
        ]);

        yield result;
      } else if (result is DownloadProgress) {
        progressListener?.call(result);

        if (result.progress != null)
          devLog([
            'Download progress: ${(result.progress! * 100).toStringAsFixed(1)}% for ${Utils.getFileNameOrUrl(result.originalUrl)}'
          ]);
      }
    }
  }

  /// Checks whether the given [url] can be loaded directly from cache.
  ///
  /// - **REQUIRED** The [url] property is used to specify the url
  ///   for the required font. It should be a valid http/https url which points to
  ///   a font file. The [url] should match the url passed to [cacheFont].
  static Future<bool> canLoadFont(String url) async {
    WidgetsFlutterBinding.ensureInitialized();

    final String cacheKey = Utils.sanitizeUrl(url);

    final FileInfo? font =
        await DynamicCachedFontsCacheManager.getCacheManager(cacheKey).getFileFromCache(cacheKey);

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
  static Future<FileInfo> loadCachedFont(
    String url, {
    required String fontFamily,
    @visibleForTesting FontLoader? fontLoader,
  }) async {
    fontLoader ??= FontLoader(fontFamily);

    WidgetsFlutterBinding.ensureInitialized();

    final String cacheKey = Utils.sanitizeUrl(url);

    final FileInfo? font =
        await DynamicCachedFontsCacheManager.getCacheManager(cacheKey).getFileFromCache(cacheKey);

    if (font == null) throw StateError('Font should already be cached to be loaded');

    final Uint8List fontBytes = await font.file.readAsBytes();

    final ByteData cachedFontBytes = ByteData.view(fontBytes.buffer);

    fontLoader.addFont(
      Future<ByteData>.value(cachedFontBytes),
    );

    await fontLoader.load();

    devLog(<String>[
      'Font has been loaded!',
      'This font file is valid till - ${font.validTill}',
      'File stat - ${font.file.statSync()}'
    ]);

    return font;
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
  static Future<Iterable<FileInfo>> loadCachedFamily(
    List<String> urls, {
    required String fontFamily,
    @visibleForTesting FontLoader? fontLoader,
  }) async {
    fontLoader ??= FontLoader(fontFamily);
    final List<FileInfo> fonts = [];

    WidgetsFlutterBinding.ensureInitialized();

    for (final String url in urls) {
      final String cacheKey = Utils.sanitizeUrl(url);

      final FileInfo? font =
          await DynamicCachedFontsCacheManager.getCacheManager(cacheKey).getFileFromCache(cacheKey);

      if (font == null) throw StateError('Font should already be cached to be loaded');

      fonts.add(font);

      final Uint8List fontBytes = await font.file.readAsBytes();

      final ByteData cachedFontBytes = ByteData.view(fontBytes.buffer);

      fontLoader.addFont(Future<ByteData>.value(cachedFontBytes));
    }

    await fontLoader.load();

    devLog(<String>['Font has been loaded!']);

    return fonts;
  }

  /// Fetches the given [urls] from cache and loads them into the engine to be used.
  /// A stream of [FileInfo] objects is returned, which emits the font files as they
  /// are loaded. The total number of files returned corresponds to the number of
  /// urls provided. The download progress can be listened to using [progressListener].
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
  /// - The [progressListener] property is used to listen to the download progress
  ///   of the font. It gives information about the number of files
  ///   downloaded and the total number of files to be downloaded.
  ///   It is called with
  ///
  ///   a [double] value which indicates the fraction of items that have been downloaded,
  ///   an [int] value which indicates the total number of items to be downloaded and,
  ///   another [int] value which indicates the number of items that have been
  ///   downloaded so far.
  static Stream<FileInfo> loadCachedFamilyStream(
    List<String> urls, {
    required String fontFamily,
    required ItemCountProgressListener? progressListener,
    @visibleForTesting FontLoader? fontLoader,
  }) async* {
    fontLoader ??= FontLoader(fontFamily);

    WidgetsFlutterBinding.ensureInitialized();

    for (final String url in urls) {
      final String cacheKey = Utils.sanitizeUrl(url);

      final FileInfo? font =
          await DynamicCachedFontsCacheManager.getCacheManager(cacheKey).getFileFromCache(cacheKey);

      if (font == null) throw StateError('Font should already be cached to be loaded');

      final Uint8List fontBytes = await font.file.readAsBytes();
      final ByteData bytes = ByteData.view(fontBytes.buffer);

      fontLoader.addFont(Future.value(bytes));

      final totalItems = urls.length, downloadedItems = urls.indexOf(url) + 1;

      progressListener?.call(
        downloadedItems / totalItems,
        totalItems,
        downloadedItems,
      );

      devLog([
        'Downloaded $downloadedItems of $totalItems fonts (${((downloadedItems / totalItems) * 100).toStringAsFixed(1)}%)'
      ]);

      yield font;
    }

    await fontLoader.load();

    devLog(<String>['Font has been loaded!']);
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

    await DynamicCachedFontsCacheManager.getCacheManager(cacheKey).removeFile(cacheKey);
  }
}
