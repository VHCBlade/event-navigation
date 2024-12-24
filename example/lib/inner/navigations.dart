import 'package:event_navigation/event_navigation.dart';

class AboutDeepNavigationStrategy
    implements DeepNavigationStrategy<String> {
  @override
  bool shouldAcceptNavigation(String subNavigation, DeepNavigationNode? root) {
    if (root == null) {
      return subNavigation == "changelog";
    }

    return false;
  }
}
