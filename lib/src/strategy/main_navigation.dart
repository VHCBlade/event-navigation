/// Details which navigations are to be accepted and what to do when navigation is not accepted.
///
/// [ListNavigationStrategy] is the default implementation of this.
abstract class MainNavigationStrategy<T> {
  static String defaultConvert<T>(T val) => '$val';
  static T defaultStringToValue<T>(String val) => val as T;

  /// Checks to see if the desired [newNavigation] is a valid main navigation.
  bool attemptNavigation(T newNavigation);

  /// The navigation when the user attempts to navigate to an undefined page.
  T get navigationOnError;

  /// The navigation that the user defaults to.
  T get defaultNavigation;

  String Function(T) get convertToString => defaultConvert;
  T Function(String) get convertToValue => defaultStringToValue;
}

class ListNavigationStrategy<T> implements MainNavigationStrategy<T> {
  final List<T> possibleNavigations;

  final String Function(T)? convertToStringFunction;
  final T Function(String)? convertToValueFunction;

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
  T Function(String p1) get convertToValue =>
      convertToValueFunction ?? MainNavigationStrategy.defaultStringToValue;
}
