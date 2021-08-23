import 'package:event_bloc/event_bloc.dart';
import 'package:event_navigation/event_navigation.dart';
import 'package:event_navigation/src/event.dart';
import 'package:event_navigation/src/strategy/main_navigation.dart';
import 'package:event_navigation/src/strategy/navigation_undo.dart';

/// This [Bloc] handles the main/top level navigation of this app. Check values in [POSSIBLE_NAVIGATION] for possible main navigation values. You can fire the [MAIN_NAVIGATION_EVENT] and [PREVIOUS_MAIN_NAVIGATION_EVENT] to call the corresponding functions indirectly.
///
/// Defaults to home and will change the main navigation to home if it is attempted to change the app to an unknown state.
class MainNavigationBloc<T> extends Bloc {
  @override
  final BlocEventChannel eventChannel;
  final MainNavigationStrategy<T> strategy;
  final NavigationUndoStrategy<T> undoStrategy;

  final deepNavigationStrategyMap = <T, DeepNavigationStrategy>{};
  final deepNavigationMap = <T, DeepNavigationNode<T>>{};

  T currentMainNavigation;

  MainNavigationBloc({
    BlocEventChannel? parentChannel,
    required T defaultNavigation,
    required this.strategy,
    required this.undoStrategy,
  })  : eventChannel = BlocEventChannel(parentChannel),
        currentMainNavigation = defaultNavigation {
    eventChannel.addEventListener(MAIN_NAVIGATION_EVENT,
        BlocEventChannel.simpleListener((val) => changeMainNavigation(val)));
    eventChannel.addEventListener(PREVIOUS_MAIN_NAVIGATION_EVENT,
        BlocEventChannel.simpleListener((_) => undoNavigation()));
  }

  /// Changes the main navigation to the [newMainNavigation], if applicable.
  ///
  /// If [logUndo] is false, the navigation will not be logged in the undo strategy.
  void changeMainNavigation(T newMainNavigation, {bool logUndo = true}) {
    if (!strategy.attemptNavigation(newMainNavigation)) {
      assert(strategy.attemptNavigation(strategy.navigationOnError));

      changeMainNavigation(strategy.navigationOnError);
      return;
    }

    if (currentMainNavigation == newMainNavigation) {
      return;
    }

    if (logUndo) {
      undoStrategy.logNavigation(currentMainNavigation, newMainNavigation);
    }
    currentMainNavigation = newMainNavigation;
    updateBloc();
  }

  void undoNavigation() => undoStrategy.canUndo()
      ? changeMainNavigation(undoStrategy.undoNavigation(), logUndo: false)
      : null;

  void redoNavigation() => undoStrategy.canRedo()
      ? changeMainNavigation(undoStrategy.redoNavigation(), logUndo: false)
      : null;
}
