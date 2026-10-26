import 'package:event_bloc/event_bloc.dart';

import 'deep_navigation.dart';
import 'event.dart';
import 'strategy/deep_navigation.dart';
import 'strategy/main_navigation.dart';
import 'strategy/navigation_undo.dart';

enum NavigationResult {
  success,
  failed,
  same,
}

/// This [Bloc] handles the main/top level navigation of this app. You can fire events in event.dart or use the functions in [EventNavigation] to call the functions indirectly.
///
/// This uses [MainNavigationStrategy] to decide which main navigations to accept and how to convert the [T] to and from a String.
/// [T] does not have to be a [String]: by default values are written to the full navigation string with [Object.toString].
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
    return fullNavigationOnMainNavigation(currentMainNavigation);
  }

  /// The full navigation, as a String, that [mainNavigation] currently has, including its own deep navigation.
  String fullNavigationOnMainNavigation(T mainNavigation) {
    final mainNavigationString = strategy.convertToString(mainNavigation);
    final subNavigationString = deepNavigationMap[mainNavigation]
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
    eventChannel.addEventListener(
      NavigationEvent.mainNavigation.event,
      (_, val) => changeMainNavigation(val as T),
      allowDynamic: true,
    );
    eventChannel.addEventListener<String>(
        NavigationEvent.deepLinkNavigation.event,
        (_, val) => changeFullNavigation(val));
    eventChannel.addEventListener<void>(
      NavigationEvent.previousMainNavigation.event,
      (_, val) => undoNavigation(),
    );
  }

  void _addDeepNavigationListeners() {
    eventChannel.addEventListener<void>(
      NavigationEvent.popDeepNavigation.event,
      (_, val) => popDeepNavigation(),
    );
    eventChannel.addEventListener(
      NavigationEvent.pushDeepNavigation.event,
      (_, val) => pushDeepNavigation(val as T),
      allowDynamic: true,
    );
    eventChannel.addEventListener<String>(
      NavigationEvent.appendDeepNavigation.event,
      (_, val) => changeFullNavigation("$fullNavigation/$val"),
    );
  }

  /// Changes the current navigation to be equal to the [newFullNavigation].
  ///
  /// Upon failure, will set [lastFailedFullNavigation] to [newFullNavigation]
  void changeFullNavigation(String newFullNavigation, {bool updateBloc = true}) {
    if (!updateBloc) {
      _changeFullNavigation(newFullNavigation);
      return;
    }
    updateBlocOnChange(
        change: () => _changeFullNavigation(newFullNavigation),
        tracker: () => [fullNavigation, lastFailedFullNavigation]);
  }

  /// Changes the current navigation to be equal to the [newFullNavigation].
  ///
  /// Segments are converted with [MainNavigationStrategy.convertToValue]. A segment
  /// that converts to null is treated as an unknown navigation.
  ///
  /// Upon failure, will set [lastFailedFullNavigation] to [newFullNavigation].
  void _changeFullNavigation(String newFullNavigation) {
    if (newFullNavigation.isEmpty) {
      newFullNavigation = strategy.convertToString(strategy.defaultNavigation);
    }

    final segments = newFullNavigation.split('/');

    final mainNavigation = strategy.convertToValue(segments[0]);
    if (mainNavigation == null) {
      navigateToError();
      logFailedNavigation(newFullNavigation);
      return;
    }

    final mainNavigationResult = changeMainNavigation(
      mainNavigation,
      logUndo: false,
      shouldUpdateBloc: false,
    );

    if (mainNavigationResult == NavigationResult.failed) {
      logFailedNavigation(newFullNavigation);
      return;
    }

    final subNavigations = <T>[];
    for (final segment in segments.skip(1)) {
      final subNavigation = strategy.convertToValue(segment);
      if (subNavigation == null) {
        navigateToError();
        logFailedNavigation(newFullNavigation);
        return;
      }
      subNavigations.add(subNavigation);
    }

    final subNavigationResult = handleDeepNavigationFromRoot(subNavigations);

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

    final previous = deepNavigationMap[currentMainNavigation];
    if (previous == node) {
      return NavigationResult.same;
    }

    deepNavigationMap[currentMainNavigation] = node;
    undoStrategy.logDeepNavigation(currentMainNavigation, previous, node);

    return NavigationResult.success;
  }

  /// Adds [value] as the new leaf of the deep navigation of [currentMainNavigation], if the
  /// [DeepNavigationStrategy] accepts it. Otherwise navigates to the error navigation.
  ///
  /// This is synchronous.
  NavigationResult pushDeepNavigation(T value, {bool shouldUpdateBloc = true}) {
    final deepNavigationStrategy =
        getDeepNavigationStrategy(currentMainNavigation);

    if (!deepNavigationStrategy.shouldAcceptNavigation(
        value, currentDeepNavigation)) {
      navigateToError(shouldUpdateBloc: shouldUpdateBloc);
      return NavigationResult.failed;
    }

    final previous = currentDeepNavigation;
    final node = previous?.setLeaf(DeepNavigationNode<T>(value)) ??
        DeepNavigationNode<T>(value);
    currentDeepNavigation = node;
    undoStrategy.logDeepNavigation(currentMainNavigation, previous, node);

    if (shouldUpdateBloc) {
      updateBloc();
    }
    return NavigationResult.success;
  }

  /// Will attempt to pop the deep navigation node of [currentMainNavigation]. If currently at the base layer, this will do nothing.
  void popDeepNavigation() {
    updateBlocOnChange(
        change: () {
          final previous = currentDeepNavigation;
          if (previous == null) {
            return;
          }
          final node = previous.removeLeaf();
          currentDeepNavigation = node;
          undoStrategy.logDeepNavigation(currentMainNavigation, previous, node);
        },
        tracker: () => [currentDeepNavigation]);
  }

  /// Changes the main navigation to the [newMainNavigation], if applicable.
  ///
  /// If [logUndo] is false, the navigation will not be logged in the undo strategy.
  ///
  /// If [shouldUpdateBloc] is false, listeners are not notified, including when this
  /// has to navigate to the error navigation.
  ///
  /// returns [NavigationResult.failed] if the navigation was rejected, [NavigationResult.same]
  /// if it is already the current navigation, and [NavigationResult.success] otherwise.
  NavigationResult changeMainNavigation(T newMainNavigation,
      {bool logUndo = true, bool shouldUpdateBloc = true}) {
    if (!strategy.attemptNavigation(newMainNavigation)) {
      assert(strategy.attemptNavigation(strategy.navigationOnError));

      navigateToError(shouldUpdateBloc: shouldUpdateBloc);
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

  void undoNavigation() {
    if (!undoStrategy.canUndo()) {
      return;
    }
    changeMainNavigation(undoStrategy.undoNavigation(), logUndo: false);
  }

  void redoNavigation() {
    if (!undoStrategy.canRedo()) {
      return;
    }
    changeMainNavigation(undoStrategy.redoNavigation(), logUndo: false);
  }
}
