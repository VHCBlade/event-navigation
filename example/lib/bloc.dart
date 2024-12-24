import 'package:event_navigation/event_navigation.dart';
import 'package:event_bloc/event_bloc.dart';
import 'package:event_navigation_example/inner/blog.dart';
import 'package:event_navigation_example/inner/navigations.dart';

const possibleNavigations = <String>{"home", "apps", "blog", "about", "error"};

MainNavigationBloc<String> generateNavigationBloc(
    BlocEventChannel? parentChannel) {
  return MainNavigationBloc<String>(
    parentChannel: parentChannel,
    strategy: ListNavigationStrategy(
        possibleNavigations: possibleNavigations.toList(),
        navigationOnError: "error",
        defaultNavigation: "home"),
    undoStrategy: UndoRedoMainNavigationStrategy(),
  )
    ..deepNavigationStrategyMap["about"] = AboutDeepNavigationStrategy()
    ..deepNavigationStrategyMap["blog"] = BlogDeepNavigationStrategy();
}
