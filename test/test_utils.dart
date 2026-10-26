import 'package:event_bloc/event_bloc_widgets.dart';
import 'package:event_navigation/event_navigation.dart';
import 'package:flutter/material.dart';

const testNavigations = ['home', 'blog', 'about', 'error'];

/// Builds a bloc with string navigations. Deep navigation is accepted unless [deepStrategy] says otherwise.
MainNavigationBloc<String> buildBloc({
  BlocEventChannel? parentChannel,
  String defaultNavigation = 'home',
  DeepNavigationStrategy? deepStrategy,
  NavigationUndoStrategy<String>? undoStrategy,
}) =>
    MainNavigationBloc<String>(
      parentChannel: parentChannel,
      strategy: ListNavigationStrategy<String>(
        possibleNavigations: testNavigations,
        navigationOnError: 'error',
        defaultNavigation: defaultNavigation,
      ),
      undoStrategy: undoStrategy ?? UndoRedoMainNavigationStrategy<String>(),
      defaultDeepNavigationStrategy:
          deepStrategy ?? DeepNavigationStrategy.acceptEverything,
    );

/// Wraps [child] in a [BlocProvider] with a bloc that is connected to the widget tree's event channel.
///
/// [onBloc] is called with the created bloc so tests can inspect and drive it.
Widget blocApp({
  required Widget child,
  required void Function(MainNavigationBloc<String>) onBloc,
  String defaultNavigation = 'home',
}) {
  return BlocProvider(
    create: (_, channel) {
      final bloc = buildBloc(
        parentChannel: channel,
        defaultNavigation: defaultNavigation,
      );
      onBloc(bloc);
      return bloc;
    },
    child: MaterialApp(home: Scaffold(body: child)),
  );
}
