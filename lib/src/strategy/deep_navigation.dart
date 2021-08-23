import 'package:event_navigation/event_navigation.dart';

abstract class DeepNavigationStrategy<T> {
  static createDefault<T>() => NullDeepNavigationStrategy<T>();
  static String defaultConvert<T>(T val) => '$val';

  Future<bool> showAcceptNavigation<T>(
      T subNavigation, DeepNavigationNode? root);

  String Function(T) get convertToString => defaultConvert;
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
  final String Function(T)? convertToStringFunction;

  DefaultListDeepNavigationStrategy(
      {required this.allowedSubNavigation, this.convertToStringFunction});

  @override
  Future<bool> showAcceptNavigation<T>(
      T subNavigation, DeepNavigationNode? root) async {
    return allowedSubNavigation.contains(subNavigation);
  }

  @override
  String Function(T) get convertToString =>
      convertToStringFunction ?? DeepNavigationStrategy.defaultConvert;
}
