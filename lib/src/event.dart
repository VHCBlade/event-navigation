import 'package:flutter/material.dart';
import 'package:event_bloc/event_bloc.dart';

const MAIN_NAVIGATION_EVENT = 'main-navigation';
const PREVIOUS_MAIN_NAVIGATION_EVENT = 'previous-main-navigation';

const DEEP_LINK_NAVIGATION_EVENT = 'deep-navigation';
const APPEND_DEEP_NAVIGATION_EVENT = 'append-navigation';
const PUSH_DEEP_NAVIGATION_EVENT = 'push-navigation';
const POP_DEEP_NAVIGATION_EVENT = 'pop-navigation';

/// Helper class that assumes you placed a [MainNavigationBloc]
class EventNavigation {
  static void changeMainNavigation<T>(
      BuildContext context, T newMainNavigation) {
    BlocEventChannelProvider.of(context)
        .fireEvent(MAIN_NAVIGATION_EVENT, newMainNavigation);
  }

  static void undoNavigation(BuildContext context) {
    BlocEventChannelProvider.of(context)
        .fireEvent(PREVIOUS_MAIN_NAVIGATION_EVENT, null);
  }

  static void deepNavigate(BuildContext context, String deepNavigationString) {
    BlocEventChannelProvider.of(context)
        .fireEvent(DEEP_LINK_NAVIGATION_EVENT, deepNavigationString);
  }

  /// TODO Doesn't work yet.
  static void appendDeepNavigation(
      BuildContext context, String addedDeepNavigationString) {
    throw UnimplementedError();
    // BlocEventChannelProvider.of(context)
    //     .fireEvent(APPEND_DEEP_NAVIGATION_EVENT, addedDeepNavigationString);
  }

  static void pushDeepNavigation<T>(
      BuildContext context, T addedDeepNavigation) {
    BlocEventChannelProvider.of(context)
        .fireEvent(PUSH_DEEP_NAVIGATION_EVENT, addedDeepNavigation);
  }

  static void popDeepNavigation(BuildContext context) {
    BlocEventChannelProvider.of(context)
        .fireEvent(POP_DEEP_NAVIGATION_EVENT, null);
  }
}
