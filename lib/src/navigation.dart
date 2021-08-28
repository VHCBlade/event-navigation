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

/// This [Bloc] handles the main/top level navigation of this app. You can fire events in event.dart or use the functions in [EventNavigation] to call the functions indirectly.
///
/// This uses [MainNavigationStrategy] to decide which main navigations to accept and how to convert the [T] to and from a String.
///
/// This also uses [deepNavigationStrategyMap] to have a mapping of [DeepNavigationStrategy]s for each individual [MainNavigation] that is allowed in the Bloc.
///
/// Defaults to home and will change the main navigation to home if it is attempted to change the app to an unknown state.
class MainNavigationBloc<T> extends Bloc {
  @override
  final BlocEventChannel eventChannel;
  final MainNavigationStrategy<T> strategy;
  final NavigationUndoStrategy<T> undoStrategy;

  final deepNavigationStrategyMap = <T, DeepNavigationStrategy>{};
  final deepNavigationMap = <T, DeepNavigationNode<T>?>{};
  String? lastFailedFullNavigation;
  bool failedLastNavigation = false;

  DeepNavigationStrategy defaultDeepNavigationStrategy;

  T currentMainNavigation;
  DeepNavigationNode<T>? get currentDeepNavigation =>
      deepNavigationMap[currentMainNavigation];

  /// This is the full navigation expressed as a String. The conversion function is provided by [MainNavigationStrategy]
  String get fullNavigation {
    final mainNavigationString =
        strategy.convertToString(currentMainNavigation);
    final subNavigationString = deepNavigationMap[currentMainNavigation]
        ?.convertNodeToString(strategy.convertToString);

    return '$mainNavigationString${subNavigationString ?? ""}';
  }

  /// [defaultDeepNavigationStrategy] is the strategy used when [deepNavigationStrategyMap] doesn't have a strategy for the [currentMainNavigationStrategy]
  MainNavigationBloc({
    BlocEventChannel? parentChannel,
    required this.strategy,
    required this.undoStrategy,
    this.defaultDeepNavigationStrategy = DeepNavigationStrategy.denyEverything,
  })  : eventChannel = BlocEventChannel(parentChannel),
        currentMainNavigation = strategy.defaultNavigation {
    eventChannel.addEventListener(MAIN_NAVIGATION_EVENT,
        BlocEventChannel.simpleListener((val) => changeMainNavigation(val)));
    eventChannel.addEventListener(DEEP_LINK_NAVIGATION_EVENT,
        BlocEventChannel.simpleListener((val) => changeFullNavigation(val)));
    eventChannel.addEventListener(PREVIOUS_MAIN_NAVIGATION_EVENT,
        BlocEventChannel.simpleListener((_) => undoNavigation()));
  }

  /// Changes the current navigation to be equal to the [newFullNavigation].
  ///
  /// Upon failure, will set [lastFailedFullNavigation] to [newFullNavigation]
  void changeFullNavigation(String newFullNavigation,
      {bool updateBloc = true}) async {
    if (!updateBloc) {
      changeFullNavigation(newFullNavigation);
      return;
    }
    updateBlocOnFutureChange(
        change: () => _changeFullNavigation(newFullNavigation),
        tracker: () => [fullNavigation, lastFailedFullNavigation]);
  }

  /// Changes the current navigation to be equal to the [newFullNavigation].
  ///
  /// Upon failure, will set [lastFailedFullNavigation] to [newFullNavigation].
  Future<void> _changeFullNavigation(String newFullNavigation) async {
    if (newFullNavigation.isEmpty) {
      newFullNavigation = strategy.convertToString(strategy.defaultNavigation);
    }

    final value = newFullNavigation.split('/');

    final mainNavigationResult = changeMainNavigation(
      strategy.convertToValue(value[0]),
      logUndo: false,
      shouldUpdateBloc: false,
    );

    if (mainNavigationResult == NavigationResult.failed) {
      logFailedNavigation(newFullNavigation);
      return;
    }

    final subNavigationResult = await handleSubNavigationFromRoot(
        value.skip(1).map((val) => strategy.convertToValue(val)));

    if (subNavigationResult != NavigationResult.failed) {
      return;
    }

    changeMainNavigation(strategy.navigationOnError, shouldUpdateBloc: false);
    logFailedNavigation(newFullNavigation);
  }

  void logSuccessfulNavigation() {
    failedLastNavigation = false;
  }

  void logFailedNavigation(String failedNavigation) {
    failedLastNavigation = true;
    lastFailedFullNavigation = failedNavigation;
  }

  DeepNavigationStrategy getDeepNavigationStrategy(T mainNavigation) =>
      deepNavigationStrategyMap[mainNavigation] ??
      defaultDeepNavigationStrategy;

  /// Will create a new [DeepNavigationNode] to assign to [currentMainNavigation] that starts from the base layer.
  Future<NavigationResult> handleSubNavigationFromRoot(
      Iterable<T> subNavigations) async {
    final deepNavigationStrategy =
        getDeepNavigationStrategy(currentMainNavigation);

    DeepNavigationNode<T>? node;

    for (final subNavigation in subNavigations) {
      if (!await deepNavigationStrategy.shouldAcceptNavigation(
          subNavigation, node)) {
        return NavigationResult.failed;
      }

      node = node?.setLeaf(DeepNavigationNode(subNavigation)) ??
          DeepNavigationNode(subNavigation);
    }
    logSuccessfulNavigation();

    if (deepNavigationMap[currentMainNavigation] == node) {
      return NavigationResult.same;
    }

    deepNavigationMap[currentMainNavigation] = node;

    return NavigationResult.success;
  }

  /// Changes the main navigation to the [newMainNavigation], if applicable.
  ///
  /// If [logUndo] is false, the navigation will not be logged in the undo strategy.
  ///
  /// returns true if the navigation was successful. False otherwise
  NavigationResult changeMainNavigation(T newMainNavigation,
      {bool logUndo = true, bool shouldUpdateBloc = true}) {
    if (!strategy.attemptNavigation(newMainNavigation)) {
      assert(strategy.attemptNavigation(strategy.navigationOnError));

      changeMainNavigation(strategy.navigationOnError);
      return NavigationResult.failed;
    }

    logSuccessfulNavigation();

    if (currentMainNavigation == newMainNavigation) {
      return NavigationResult.same;
    }

    if (logUndo) {
      undoStrategy.logNavigation(currentMainNavigation, newMainNavigation);
    }
    currentMainNavigation = newMainNavigation;
    if (shouldUpdateBloc) {
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
