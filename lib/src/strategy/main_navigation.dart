/// Details which navigations are to be accepted and what to do when navigation is not accepted.
///
/// The navigation type [T] does not need to be a [String]. By default, a value is converted
/// to its path segment with [Object.toString]. Converting a path segment back into a [T] is
/// handled by [convertToValue], which returns null when the segment is not recognized.
///
/// [ListNavigationStrategy] is the default implementation of this.
abstract class MainNavigationStrategy<T> {
  /// Converts [val] to a path segment using [Object.toString].
  static String defaultConvert<T>(T val) => '$val';

  /// Returns [val] if [T] can hold a [String], otherwise null.
  ///
  /// Anything that is not a [String] (enums, ints, custom classes) needs a custom
  /// [convertToValue]. [ListNavigationStrategy] provides one that matches against its
  /// possible navigations.
  static T? defaultStringToValue<T>(String val) => val is T ? val as T : null;

  /// Checks to see if the desired [newNavigation] is a valid main navigation.
  bool attemptNavigation(T newNavigation);

  /// The navigation when the user attempts to navigate to an undefined page.
  T get navigationOnError;

  /// The navigation that the user defaults to.
  T get defaultNavigation;

  /// Converts a navigation to the path segment used in the full navigation string.
  String Function(T) get convertToString => defaultConvert;

  /// Converts a path segment back to a navigation. Must return null if [String] does
  /// not correspond to any navigation, which causes the navigation to fail.
  T? Function(String) get convertToValue => defaultStringToValue;
}

/// Accepts any navigation contained in [possibleNavigations].
///
/// Path segments are matched against [possibleNavigations] using [convertToString]
/// (which is [Object.toString] unless [convertToStringFunction] is provided), so [T]
/// can be an enum or any other type with a stable string form.
class ListNavigationStrategy<T> implements MainNavigationStrategy<T> {
  final List<T> possibleNavigations;

  final String Function(T)? convertToStringFunction;
  final T? Function(String)? convertToValueFunction;

  @override
  final T navigationOnError;
  @override
  final T defaultNavigation;

  ListNavigationStrategy({
    required this.possibleNavigations,
    T? navigationOnError,
    T? defaultNavigation,
    this.convertToStringFunction,
    this.convertToValueFunction,
  })  : assert(possibleNavigations.isNotEmpty),
        navigationOnError = navigationOnError ?? possibleNavigations[0],
        defaultNavigation = defaultNavigation ?? possibleNavigations[0];

  @override
  bool attemptNavigation(T newNavigation) =>
      possibleNavigations.contains(newNavigation);

  @override
  String Function(T) get convertToString =>
      convertToStringFunction ?? MainNavigationStrategy.defaultConvert;

  @override
  T? Function(String) get convertToValue =>
      convertToValueFunction ?? _matchPossibleNavigation;

  T? _matchPossibleNavigation(String val) {
    final convert = convertToString;
    for (final navigation in possibleNavigations) {
      if (convert(navigation) == val) {
        return navigation;
      }
    }
    return MainNavigationStrategy.defaultStringToValue<T>(val);
  }
}
