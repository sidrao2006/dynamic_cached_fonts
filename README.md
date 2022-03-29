# Dynamic Cached Fonts

[![Pub Version][pub-version-badge]][pub-package]
![Supported Platforms][supported-platforms-badge]

<!-- CI badges -->
[![Unit Tests][unit-tests-badge]][unit-tests]
[![Integration Tests][integration-tests-badge]][integration-tests]

A simple, easy to use yet customizable font loader to use web fonts.

Demo: https://sidrao2006.github.io/dynamic_cached_fonts

![Demo 3]

## 👋 Introduction

Dynamic Cached Fonts allows you to dynamically load a font from any url and cache it. This way, you can reduce your bundle size and load the font if and when it's required.

Another advantage of dynamically loading fonts is that you can now easily provide an option to your users to pick an app font. This allows for a greater level of customization.

Caching is an added performance upgrade as the font will be downloaded only once and used multiple times, reducing network and battery usage.

## 🏃 Get Started

To use the package, add `dynamic_cached_fonts` as a [dependency][install].

## ⚒️ Usage

### Loading fonts on demand

You can load font on demand, for example - when a page loads

```dart
@override
void initState() {
  final DynamicCachedFonts dynamicCachedFont = DynamicCachedFonts(
    fontFamily: fontFamilyName, // The font family name to be passed to TextStyle.fontFamily
    url: fontUrl, // A valid url pointing to a font file (.ttf or .otf files only) 
  );
  dynamicCachedFont.load(); // Downloads the font, caches and loads it.

  super.initState();
}
...
Text(
  'Some Text',
  style: TextStyle(fontFamily: fontFamilyName),
)
```

![Demo 1]

Or when a button is clicked

```dart
ElevatedButton(
  onPressed: () {
    final DynamicCachedFonts dynamicCachedFont = DynamicCachedFonts(
      fontFamily: fontFamilyName,
      url: fontUrl,
    );

    dynamicCachedFont.load();
  },
  child: const Text('Load Font'),
),
```

![Demo 2]

If you want to change how large the cache can be or maybe how long the font stays in cache, pass in `maxCacheObjects` and `cacheStalePeriod`.

```dart
DynamicCachedFonts(
  fontFamily: fontFamilyName,
  url: fontUrl,
  maxCacheObjects: 150,
  cacheStalePeriod: const Duration(days: 100),
);
```

`TextStyle.fontFamily`s are applied only after `load()` is called.

> Calling `load()` more than once throws a `StateError`

What if you need to load multiple fonts, of varying weights and styles, as a single family...For that, you can use the `DynamicCachedFonts.family` constructor.

It accepts a list of urls, pointing to different fonts in the same family, as `urls`.

```dart
DynamicCachedFonts.family(
  urls: <String>[
    fontFamilyNameBoldUrl,
    fontFamilyNameItalicUrl,
    fontFamilyNameRegularUrl,
    fontFamilyNameThinUrl,
  ],
  fontFamily: fontFamilyName,
);
```

![Demo 5]

The package also supports loading the fonts as a `Stream`! The `loadStream` returns a **single subscription stream** which emits the font files.

`loadStream` accepts a callback, `downloadProgressListener`, that is called each time a `DownloadProgress` event is received. This happens only when the font is actually being downloaded from the provided url. Subsequent requests, which are usually served from the cache, do not emit any progress events. If the font file has expired, then the file will be downloaded again for which the progress events will be streamed to `downloadProgressListener`.

When `loadStream` is called with a single font url, then `itemCountProgressListener` will be called only once when the font has been loaded into the engine.

```dart
final DynamicCachedFonts dynamicCachedFont = DynamicCachedFonts(
  fontFamily: fontFamilyName,
  url: fontUrl,
);

dynamicCachedFont.loadStream(
  itemCountProgressListener: (double progress, int totalItems, int downloadedItems) {},
  downloadProgressListener: (DownloadProgress progress) {},
);
```

And when `loadStream` is used to load an entire font family, `itemCountProgressListener` will be called once for every font in the family.
In the example given below, `itemCountProgressListener` will be called 4 times, once after every font has been loaded into the Flutter engine.

```dart
final DynamicCachedFonts dynamicCachedFont = DynamicCachedFonts.family(
  urls: <String>[
    fontFamilyNameBoldUrl,
    fontFamilyNameItalicUrl,
    fontFamilyNameRegularUrl,
    fontFamilyNameThinUrl,
  ],
  fontFamily: fontFamilyName,
);

dynamicCachedFont.loadStream(
  itemCountProgressListener: (double progress, int totalItems, int downloadedItems) {},
  downloadProgressListener: (DownloadProgress progress) {},
);
```

> Calling `loadStream` more than once throws a `StateError`

![Demo 6]

If you need more control, use the static methods!

#### `cacheFont`

```dart
onPressed: () {
  DynamicCachedFonts.cacheFont(fontUrl);
},
child: const Text('Download font'),
```

You can pass in `maxCacheObjects` and `cacheStalePeriod` here as well.

#### `canLoadFont`, `loadCachedFont`, `loadCachedFamily`

`canLoadFont` is used to check whether the font is available in cache. It is usually used in combination with the `loadCached*` methods.

First, Check whether the font is already in cache. If it is, then load the font.


```dart
if(DynamicCachedFonts.canLoadFont(fontUrl)) {
  // To load a single font...
  DynamicCachedFonts.loadCachedFont(
    fontUrl,
    fontFamily: fontFamilyName,
  );

  // Or if you want to load multiple fonts as a family...
  DynamicCachedFonts.loadCachedFamily(
    <String>[
      fontFamilyNameBoldUrl,
      fontFamilyNameItalicUrl,
      fontFamilyNameRegularUrl,
      fontFamilyNameThinUrl,
    ],
    fontFamily: fontFamilyName,
  );
}
```

Now, if the font isn't available in cache, download it!

```dart
if(DynamicCachedFonts.canLoadFont(fontUrl)) {
  ...
} else {
  DynamicCachedFonts.cacheFont(fontUrl);
}
```

#### `cacheFontStream`

`cacheFontStream` is used to download and cache the font. This method is similar to `cacheFont` but returns a **single subscription `Stream`** that emits the progress of the download.
The download is streamed to the `progressListener` callback which is called each time a `DownloadProgress` event is received. This happens only when the font is actually being downloaded from the provided url. Subsequent requests, which are usually served from the cache, do not emit any progress events. If the font file has expired, then the file will be downloaded again for which the progress events will be streamed to `downloadProgressListener`.

```dart
DynamicCachedFonts.cacheFontStream(
  fontUrl,
  progressListener: (DownloadProgress progress) {},
);
```

#### `loadCachedFamilyStream`

Use `canLoadFont` to check whether the font is available in cache.

`loadCachedFamilyStream` is used to load multiple fonts into the Flutter engine, as a single font family. This method is similar to `loadCachedFamily` but returns a stream.

When `loadCachedFamilyStream` is called with a single font url, `progressListener` will be called only once when the font has been loaded into the engine.

And when `loadCachedFamilyStream` is used to load an entire font family, `progressListener` will be called once for every font in the family.
In the example given below, `progressListener` will be called 4 times, once after every font has been loaded into the Flutter engine.

```dart
DynamicCachedFonts.loadCachedFamilyStream(
  <String>[
    fontFamilyNameBoldUrl,
    fontFamilyNameItalicUrl,
    fontFamilyNameRegularUrl,
    fontFamilyNameThinUrl,
  ],
  fontFamily: fontFamilyName,
  progressListener: (double progress, int totalItems, int downloadedItems) {},
);
```

![Demo 7]

#### `removeCachedFont`

To remove a font from cache **permanently**, use `removeCachedFont`.

> Note - This does not change the font immediately until a complete app restart.

![Demo 3]

Finally, if you want to customize their implementation, extend `RawDynamicCachedFonts` and override the static methods.

Have a custom font to load from Firebase Cloud Storage? Go for the `DynamicCachedFonts.fromFirebase` constructor! It accepts a Google Cloud Storage location which is a url starting with `gs://`. Other than that, it is similar to the default constructor.

> Tip: Use `DynamicCachedFonts.toggleVerboseLogging` to log detailed statuses and configurations for debugging.

![Demo 4]

## 🐛 Bug Reports and Help

If you find a bug, please open an issue on [Github][issue_tracker] or if you need any help, let's discuss on [Github Discussions]!

## 💁 Contributing

To make things easier, you can use [docker compose] to set up a dev environment.
Just run `docker compose run linux` to set up a Linux dev environment or run `docker compose run windows` to set up a Linux dev environment.

> You need to be on a Windows machine to be able to set up a docker Windows environment.

To contribute to the package, fork the repository and open a [pull request]!

[![GitHub Forks][github-forks-badge]][github-forks]
[![Github Stars][github-stars-badge]][github-stars]

<!-- Badges -->
[supported-platforms-badge]: https://img.shields.io/badge/Platforms-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Windows%20%7C%20Linux%20%7C%20MacOS-blue?style=for-the-badge
[pub-version-badge]: https://img.shields.io/pub/v/dynamic_cached_fonts?label=Pub%20%28Latest%20Stable%29&style=for-the-badge
[unit-tests-badge]:https://github.com/sidrao2006/dynamic_cached_fonts/actions/workflows/package_unit_test.yml/badge.svg
[integration-tests-badge]: https://github.com/sidrao2006/dynamic_cached_fonts/actions/workflows/integration_test.yml/badge.svg
[github-forks-badge]: https://img.shields.io/github/forks/sidrao2006/dynamic_cached_fonts?style=social
[github-stars-badge]: https://img.shields.io/github/stars/sidrao2006/dynamic_cached_fonts?style=social

<!-- Badge Follow Up Links -->
[pub-package]: https://pub.dev/packages/dynamic_cached_fonts
[unit-tests]:https://github.com/sidrao2006/dynamic_cached_fonts/actions/workflows/package_unit_test.yml
[integration-tests]: https://github.com/sidrao2006/dynamic_cached_fonts/actions/workflows/integration_test.yml
[github-forks]: https://github.com/sidrao2006/dynamic_cached_fonts/fork
[github-stars]: https://github.com/sidrao2006/dynamic_cached_fonts

<!-- GIFs -->
[Demo 1]: https://raw.githubusercontent.com/sidrao2006/dynamic_cached_fonts/main/doc/images/demo1.gif
[Demo 2]: https://raw.githubusercontent.com/sidrao2006/dynamic_cached_fonts/main/doc/images/demo2.gif
[Demo 3]: https://raw.githubusercontent.com/sidrao2006/dynamic_cached_fonts/main/doc/images/demo3.gif
[Demo 4]: https://raw.githubusercontent.com/sidrao2006/dynamic_cached_fonts/main/doc/images/demo4.gif
[Demo 5]: https://raw.githubusercontent.com/sidrao2006/dynamic_cached_fonts/main/doc/images/demo5.gif
[Demo 6]: https://raw.githubusercontent.com/sidrao2006/dynamic_cached_fonts/main/doc/images/demo6.gif
[Demo 7]: https://raw.githubusercontent.com/sidrao2006/dynamic_cached_fonts/main/doc/images/demo7.gif

[install]: https://pub.dev/packages/dynamic_cached_fonts/install
[issue_tracker]: https://github.com/sidrao2006/dynamic_cached_fonts/issues/new/choose
[Github Discussions]: https://github.com/sidrao2006/dynamic_cached_fonts/discussions/new?category=q-a
[docker compose]: https://docs.docker.com/compose/
[pull request]: https://github.com/sidrao2006/dynamic_cached_fonts/compare/main
