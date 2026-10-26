import 'dart:math';

import 'package:flutter/material.dart';

import '../event.dart';

/// Creates a widget that has the ability to change the main navigation of the app.
///
/// This is specifically made for buttons and their equivalent. For Navigation bars, please look at [MainNavigationBar] instead.
///
/// [T] is the main navigation type of the app's [MainNavigationBloc]. It is inferred from [navigation].
class MainNavigationButton<T> extends StatelessWidget {
  final Widget Function(void Function() navFunction) builder;
  final T navigation;

  /// [navigation] refers to the target main navigation to take.
  ///
  /// the function provided in [builder] is the function that fires the corresponding event up the widget tree.
  const MainNavigationButton(
      {Key? key, required this.navigation, required this.builder})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return builder(() => context.changeMainNavigation<T>(navigation));
  }
}

/// Creates a widget that has the ability to change the main navigation of the app.
///
/// This is specifically made for Navigation Bars. For Buttons, please look at [MainNavigationButton] instead.
///
/// [T] is the main navigation type of the app's [MainNavigationBloc]. It is inferred from [currentNavigation] and [navigationPossibilities].
class MainNavigationBar<T> extends StatelessWidget {
  final Widget Function(
    int index,
    void Function(int index) onTap,
  ) builder;
  final T currentNavigation;
  final List<T> navigationPossibilities;

  /// [currentNavigation] is currently selected navigation. This will typically come from [MainNavigationBloc]
  ///
  /// the index provided in [builder] is the currently selected index in [navigationPossibilities] or 0, if none match.
  ///
  /// the function provided in [builder] is the function that fires the corresponding event up the widget tree. Pass the index of [navigationPossibilities] that you wish to navigate to.
  MainNavigationBar(
      {Key? key,
      required this.currentNavigation,
      required this.builder,
      required this.navigationPossibilities})
      : super(key: key) {
    assert(navigationPossibilities.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final index = navigationPossibilities.indexOf(currentNavigation);
    return builder(max(index, 0),
        (i) => context.changeMainNavigation<T>(navigationPossibilities[i]));
  }
}
