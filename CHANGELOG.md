# 1.0.0

**Features/Updates**

- Add `DynamicCachedFonts.cacheFontStream` and `DynamicCachedFonts.loadCachedFamilyStream` static methods to cache and load font and return the font files as `Stream`s
- Add `loadStream` instance method to `DynamicCachedFonts` to load font files as `Stream`s

**Dependency Updates**

- Remove meta from depenencies

**Internal Updates**

- Update `loadCachedFamily`'s implementation
- Remove all reserved characters from the url to generate safer cache keys

# 0.4.0

**BREAKING CHANGE: `verboseLog`, which was deprecated in v0.2.0, has been removed. `DynamicCachedFonts.toggleVerboseLogging` should be used instead**

> The online demo (i.e, the hosted example app) is now available. Check it out [here][online-demo]!!

[online-demo]: https://sidrao2006.github.io/dynamic_cached_fonts

# 0.3.1

**Dependency Updates**

- Added support for the latest version of `firebase_storage`. Minimum supported version continues to be v8.0.0

# 0.3.0

Stable Null safety release

# 0.2.0

**Dependency Updates**

- Minimum version constraint for `flutter_cache_manager` is now v3.1.2

**Features/Updates**

- **`verboseLog` is now deprecated in all APIs. `DynamicCachedFonts.toggleVerboseLogging` should be used instead to toggle verbose logging**

- **`loadCachedFont` and `loadCachedFamily` now throws a `StateError` if the font has not been cached**
- **`UnsupportedError` is thrown if the downloaded file is not a .ttf or .otf font file**
- **`DynamicCachedFonts.load` and `loadCachedFamily` now return `Future<Iterable<FileInfo>>` instead of `void`**
- **`cacheFont` and `loadCachedFont` now return `Future<FileInfo>` instead of `void`**

> No migration is required for the above 2 changes since a method/variable that expects `void` allows any other type as well.

- `DynamicCachedFonts.load` now exits and throws immediately if font has already been loaded
- Add `DynamicCachedFonts.custom` and `RawDynamicCachedFonts.custom` methods to make the API testable
- `cacheKeyFromUrl` is now exported for testing. It generates the cache key, used by the cache manager, from a given url

**Internal Updates**

- Improve file format verification logic
- Update `DynamicCachedFonts.load` logic

# 0.1.0

- **Add complete web cache support**
- Update documentation for some public and private APIs
- Disable RawDynamicCachedFonts' default constructor
- Improve logging in `RawDynamicCachedFonts.loadCachedFont` and font extension verification

# 0.0.1

Initial Release
