# 0.3.0

- Stable null safety release
- Performance improvements for `canLoadFont`

# 0.2.0

**Dependency Updates**

- Minimum version constraint for `flutter_cache_manager` is now v3.1.2

**Features/Updates**

- **`verboseLog` is not deprecated in all APIs. `DynamicCachedFonts.toggleVerboseLogging` should be used instead to toggle verbose logging**

> It's likely that support for `verboseLog` will end in v1.0.0.

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

Initial Release (Non null-safe)
