/// Base class for all screen arguments.
///
/// This abstract class serves as a foundation for all screen-specific argument classes.
/// Each screen that requires arguments should create its own class that extends this.
///
/// Example:
/// ```dart
/// // For a detail screen that needs an ID
/// class DetailScreenArgs extends RouteArgs {
///   final String id;
///   final String title;
///
///   const DetailScreenArgs({
///     required this.id,
///     required this.title,
///   });
/// }
///
/// ```
abstract class RouteArgs {
  const RouteArgs();
}
