import 'dart:math';

import 'package:event_navigation/event_navigation.dart';
import 'package:flutter/material.dart';

/// Creates a widget that has the ability to change the main navigation of the app.
///
/// This is specifically made for buttons and their equivalent. For Navigation bars, please look at [MainNavigationBar] instead.
class MainNavigationButton extends StatelessWidget {
  final Widget Function(void Function() navFunction) builder;
  final String navigation;

  /// [navigation] refers to the target main navigation path to take.
  ///
  /// the function provided in [builder] is the function that fires the corresponding event up the widget tree.
  const MainNavigationButton(
      {Key? key, required this.navigation, required this.builder})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return builder(() => context.changeMainNavigation(navigation));
  }
}

/// Creates a widget that has the ability to change the main navigation of the app.
///
/// This is specifically made for Navigation Bars. For Buttons, please look at [MainNavigationButton] instead.
class MainNavigationBar extends StatelessWidget {
  final Widget Function(
    int index,
    void Function(int index) onTap,
  ) builder;
  final String currentNavigation;
  final List<String> navigationPossibilities;

  /// [navigation] refers to the target main navigation path to take.
  ///
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
        (i) => context.changeMainNavigation(navigationPossibilities[i]));
  }
}
