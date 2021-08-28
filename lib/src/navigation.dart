import 'package:event_bloc/event_bloc.dart';
import 'package:event_navigation/event_navigation.dart';
import 'package:event_navigation/src/event.dart';
import 'package:event_navigation/src/strategy/main_navigation.dart';
import 'package:event_navigation/src/strategy/navigation_undo.dart';

enum NavigationResult {
  success,
  failed,
  same,
}

/// This [Bloc] handles the main/top level navigation of this app. Check values in [POSSIBLE_NAVIGATION] for possible main navigation values. You can fire the [MAIN_NAVIGATION_EVENT] and [PREVIOUS_MAIN_NAVIGATION_EVENT] to call the corresponding functions indirectly.
///
/// Defaults to home and will change the main navigation to home if it is attempted to change the app to an unknown state.
class MainNavigationBloc<T> extends Bloc {
  @override
  final BlocEventChannel eventChannel;
  final MainNavigationStrategy<T> strategy;
  final NavigationUndoStrategy<T> undoStrategy;

  final deepNavigationStrategyMap = <T, DeepNavigationStrategy>{};
  final deepNavigationMap = <T, DeepNavigationNode<T>?>{};
  String? lastFailedDeepNavigation;

  T currentMainNavigation;
  String get fullNavigation {
    final mainNavigationString =
        strategy.convertToString(currentMainNavigation);
    final subNavigationString = deepNavigationMap[currentMainNavigation]
        ?.convertNodeToString(strategy.convertToString);

    return '$mainNavigationString${subNavigationString ?? ""}';
  }

  MainNavigationBloc({
    BlocEventChannel? parentChannel,
    required this.strategy,
    required this.undoStrategy,
  })  : eventChannel = BlocEventChannel(parentChannel),
        currentMainNavigation = strategy.defaultNavigation {
    eventChannel.addEventListener(MAIN_NAVIGATION_EVENT,
        BlocEventChannel.simpleListener((val) => changeMainNavigation(val)));
    eventChannel.addEventListener(DEEP_LINK_NAVIGATION_EVENT,
        BlocEventChannel.simpleListener((val) => changeFullNavigation(val)));
    eventChannel.addEventListener(PREVIOUS_MAIN_NAVIGATION_EVENT,
        BlocEventChannel.simpleListener((_) => undoNavigation()));
  }

  void changeFullNavigation(String newFullNavigation) async {
    if (newFullNavigation.isEmpty) {
      newFullNavigation = strategy.convertToString(strategy.defaultNavigation);
    }

    updateBlocOnFutureChange(
        change: () async {
          final value = newFullNavigation.split('/');

          final mainNavigationResult = changeMainNavigation(
              strategy.convertToValue(value[0]),
              logUndo: false);

          if (mainNavigationResult == NavigationResult.failed) {
            lastFailedDeepNavigation = newFullNavigation;
            return;
          }

          final subNavigationResult = await handleSubNavigationFromRoot(
              value.skip(1).map((val) => strategy.convertToValue(val)));

          lastFailedDeepNavigation =
              subNavigationResult == NavigationResult.failed
                  ? newFullNavigation
                  : null;
        },
        tracker: () => [fullNavigation, lastFailedDeepNavigation]);
  }

  Future<NavigationResult> handleSubNavigationFromRoot(
      Iterable<T> subNavigations) async {
    // TODO add subNavigation logic
    return NavigationResult.success;
  }

  /// Changes the main navigation to the [newMainNavigation], if applicable.
  ///
  /// If [logUndo] is false, the navigation will not be logged in the undo strategy.
  ///
  /// returns true if the navigation was successful. False otherwise
  NavigationResult changeMainNavigation(T newMainNavigation,
      {bool logUndo = true, bool showldUpdateBloc = true}) {
    if (!strategy.attemptNavigation(newMainNavigation)) {
      assert(strategy.attemptNavigation(strategy.navigationOnError));

      changeMainNavigation(strategy.navigationOnError);
      return NavigationResult.failed;
    }

    if (currentMainNavigation == newMainNavigation) {
      return NavigationResult.same;
    }

    if (logUndo) {
      undoStrategy.logNavigation(currentMainNavigation, newMainNavigation);
    }
    currentMainNavigation = newMainNavigation;
    if (showldUpdateBloc) {
      updateBloc();
    }
    return NavigationResult.success;
  }

  void undoNavigation() => undoStrategy.canUndo()
      ? changeMainNavigation(undoStrategy.undoNavigation(), logUndo: false)
      : null;

  void redoNavigation() => undoStrategy.canRedo()
      ? changeMainNavigation(undoStrategy.redoNavigation(), logUndo: false)
      : null;
}
