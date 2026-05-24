// coverage:ignore-file
/// Marks a package as a Boot library module.
///
/// When the app's build discovers this annotation on a dependency's barrel file,
/// it calls the library's generated `$<package>Module()` function instead of
/// re-analyzing the library's source.
class BootLibrary {
  const BootLibrary();
}
