import 'package:event_navigation/event_navigation.dart';

bool _accept<T>(T _, DeepNavigationNode<T>? a) => true;
bool _deny<T>(T _, DeepNavigationNode<T>? a) => false;

/// Decides whether a sub navigation will be allowed to go through given the node.
///
/// Check out [DefaultListDeepNavigationStrategy] and [FunctionDeepNavigationStrategy] for some default implementations of this.
abstract class DeepNavigationStrategy<T> {
  static const acceptEverything = FunctionDeepNavigationStrategy(_accept);
  static const denyEverything = FunctionDeepNavigationStrategy(_deny);
  static createDefault<T>() => denyEverything;

  const DeepNavigationStrategy();

  /// Checks whether the given [subNavigation] should accepted into the [root]. If [root] is null, that means that it's at the base layer.
  bool shouldAcceptNavigation(T subNavigation, DeepNavigationNode<T>? root);
}

/// Will use the [evaluationFunction] passed in the constructor to evaluate the acceptance of the sub navigation.
class FunctionDeepNavigationStrategy<T> implements DeepNavigationStrategy<T> {
  final bool Function<T>(T, DeepNavigationNode<T>?) evaluationFunction;

  const FunctionDeepNavigationStrategy(this.evaluationFunction);

  @override
  bool shouldAcceptNavigation(T subNavigation, DeepNavigationNode<T>? root) {
    return evaluationFunction(subNavigation, root);
  }
}

/// Will accept any sub navigation so long as it falls within the values of [allowedSubNavigation].
class DefaultListDeepNavigationStrategy<T>
    implements DeepNavigationStrategy<T> {
  final List<T> allowedSubNavigation;

  DefaultListDeepNavigationStrategy({required this.allowedSubNavigation});

  @override
  bool shouldAcceptNavigation(T subNavigation, DeepNavigationNode? root) {
    return allowedSubNavigation.contains(subNavigation);
  }
}
