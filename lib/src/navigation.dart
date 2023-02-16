import 'package:event_bloc/event_bloc.dart';
import 'package:event_navigation/event_navigation.dart';

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
  set currentDeepNavigation(DeepNavigationNode<T>? node) =>
      deepNavigationMap[currentMainNavigation] = node;

  bool get canPopDeepNavigation => currentDeepNavigation != null;

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
    super.parentChannel,
    required this.strategy,
    required this.undoStrategy,
    this.defaultDeepNavigationStrategy = DeepNavigationStrategy.denyEverything,
  }) : currentMainNavigation = strategy.defaultNavigation {
    _addMainNavigationListeners();
    _addDeepNavigationListeners();
  }

  void _addMainNavigationListeners() {
    eventChannel.addEventListener(NavigationEvent.mainNavigation.event,
        (_, val) => changeMainNavigation(val as T));
    eventChannel.addEventListener<String>(
        NavigationEvent.deepLinkNavigation.event,
        (_, val) => changeFullNavigation(val));
    eventChannel.addEventListener(NavigationEvent.previousMainNavigation.event,
        (_, val) => undoNavigation());
  }

  void _addDeepNavigationListeners() {
    eventChannel.addEventListener(NavigationEvent.popDeepNavigation.event,
        (_, val) => popDeepNavigation());
    eventChannel.addEventListener(NavigationEvent.pushDeepNavigation.event,
        (_, val) => pushDeepNavigation(val as T));
    eventChannel.addEventListener<String>(
        NavigationEvent.appendDeepNavigation.event,
        (_, val) => changeFullNavigation("$fullNavigation/$val"));
  }

  /// Changes the current navigation to be equal to the [newFullNavigation].
  ///
  /// Upon failure, will set [lastFailedFullNavigation] to [newFullNavigation]
  void changeFullNavigation(String newFullNavigation,
      {bool updateBloc = true}) async {
    if (!updateBloc) {
      _changeFullNavigation(newFullNavigation);
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

    final subNavigationResult = handleDeepNavigationFromRoot(
        value.skip(1).map((val) => strategy.convertToValue(val)));

    if (subNavigationResult != NavigationResult.failed) {
      return;
    }

    navigateToError();
    logFailedNavigation(newFullNavigation);
  }

  void navigateToError({bool shouldUpdateBloc = false}) {
    changeMainNavigation(strategy.navigationOnError,
        shouldUpdateBloc: shouldUpdateBloc);
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
  NavigationResult handleDeepNavigationFromRoot(Iterable<T> subNavigations) {
    final deepNavigationStrategy =
        getDeepNavigationStrategy(currentMainNavigation);

    DeepNavigationNode<T>? node;

    for (final subNavigation in subNavigations) {
      if (!deepNavigationStrategy.shouldAcceptNavigation(subNavigation, node)) {
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

  Future<NavigationResult> pushDeepNavigation(T value,
      {bool shouldUpdateBloc = true}) async {
    final deepNavigationStrategy =
        getDeepNavigationStrategy(currentMainNavigation);

    if (!deepNavigationStrategy.shouldAcceptNavigation(
        value, currentDeepNavigation)) {
      navigateToError(shouldUpdateBloc: shouldUpdateBloc);
      return NavigationResult.failed;
    }

    currentDeepNavigation =
        currentDeepNavigation?.setLeaf(DeepNavigationNode<T>(value)) ??
            DeepNavigationNode<T>(value);

    if (shouldUpdateBloc) {
      updateBloc();
    }
    return NavigationResult.success;
  }

  /// Will attempt to pop the deep navigation node of [currentMainNavigation]. If currently at the base layer, this will do nothing.
  void popDeepNavigation() {
    updateBlocOnChange(
        change: () =>
            currentDeepNavigation = currentDeepNavigation?.removeLeaf(),
        tracker: () => [currentDeepNavigation]);
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

      navigateToError(shouldUpdateBloc: true);
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
