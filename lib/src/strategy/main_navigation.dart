/// Details which navigations are to be accepted and what to do when navigation is not accepted.
///
/// [ListNavigationStrategy] is the default implementation of this.
abstract class MainNavigationStrategy<T> {
  /// Checks to see if the desired [newNavigation] is a valid main navigation.
  bool attemptNavigation(T newNavigation);

  /// The navigation
  T get navigationOnError;
}

class ListNavigationStrategy<T> implements MainNavigationStrategy<T> {
  final List<T> possibleNavigations;
  @override
  T navigationOnError;

  ListNavigationStrategy(
      {required this.possibleNavigations, T? navigationOnError})
      : assert(possibleNavigations.isNotEmpty),
        navigationOnError = possibleNavigations[0];

  @override
  bool attemptNavigation(T newNavigation) {
    return possibleNavigations.contains(newNavigation);
  }
}
