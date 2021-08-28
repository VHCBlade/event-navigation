import 'package:event_navigation/event_navigation.dart';

Future<bool> _accept<T>(T _, DeepNavigationNode<T>? _a) async => true;
Future<bool> _deny<T>(T _, DeepNavigationNode<T>? _a) async => false;

/// Decides whether a sub navigation will be allowed to go through given the node.
///
/// Check out [DefaultListDeepNavigationStrategy] and [FunctionDeepNavigationStrategy] for some default implementations of this.
abstract class DeepNavigationStrategy<T> {
  static const acceptEverything = FunctionDeepNavigationStrategy(_accept);
  static const denyEverything = FunctionDeepNavigationStrategy(_deny);
  static createDefault<T>() => denyEverything;

  const DeepNavigationStrategy();

  /// Checks whether the given [subNavigation] should accepted into the [root]. If [root] is null, that means that it's at the base layer.
  Future<bool> shouldAcceptNavigation<T>(
      T subNavigation, DeepNavigationNode<T>? root);
}

/// Will use the [evaluationFunction] passed in the constructor to evaluate the acceptance of the sub navigation.
class FunctionDeepNavigationStrategy<T> implements DeepNavigationStrategy<T> {
  final Future<bool> Function<T>(T, DeepNavigationNode<T>?) evaluationFunction;

  const FunctionDeepNavigationStrategy(this.evaluationFunction);

  @override
  Future<bool> shouldAcceptNavigation<T>(
      T subNavigation, DeepNavigationNode<T>? root) {
    return evaluationFunction(subNavigation, root);
  }
}

/// Will accept any sub navigation so long as it falls within the values of [allowedSubNavigation].
class DefaultListDeepNavigationStrategy<T>
    implements DeepNavigationStrategy<T> {
  final List<T> allowedSubNavigation;

  DefaultListDeepNavigationStrategy({required this.allowedSubNavigation});

  @override
  Future<bool> shouldAcceptNavigation<T>(
      T subNavigation, DeepNavigationNode? root) async {
    return allowedSubNavigation.contains(subNavigation);
  }
}
