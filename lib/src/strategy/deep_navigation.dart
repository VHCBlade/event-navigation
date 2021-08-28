import 'package:event_navigation/event_navigation.dart';

abstract class DeepNavigationStrategy<T> {
  static createDefault<T>() => NullDeepNavigationStrategy<T>();

  Future<bool> showAcceptNavigation<T>(
      T subNavigation, DeepNavigationNode? root);
}

class NullDeepNavigationStrategy<T> extends DeepNavigationStrategy<T> {
  @override
  Future<bool> showAcceptNavigation<T>(
      T subNavigation, DeepNavigationNode? root) async {
    // deny everything.
    return false;
  }
}

class DefaultListDeepNavigationStrategy<T>
    implements DeepNavigationStrategy<T> {
  final List<T> allowedSubNavigation;

  DefaultListDeepNavigationStrategy({required this.allowedSubNavigation});

  @override
  Future<bool> showAcceptNavigation<T>(
      T subNavigation, DeepNavigationNode? root) async {
    return allowedSubNavigation.contains(subNavigation);
  }
}
