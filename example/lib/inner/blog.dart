import 'package:event_navigation/event_navigation.dart';

class BlogDeepNavigationStrategy implements DeepNavigationStrategy<String> {
  @override
  bool shouldAcceptNavigation(String subNavigation, DeepNavigationNode? root) {
    if (root == null) {
      return true;
    }

    if (root.leaf.level == 0) {
      return true;
    }

    return false;
  }
}
