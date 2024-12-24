import 'package:event_bloc/event_bloc_widgets.dart';
import 'package:event_navigation/event_navigation.dart';
import 'package:flutter/material.dart';

enum NavigationEvent<T> {
  mainNavigation<dynamic>(),
  previousMainNavigation<void>(),

  deepLinkNavigation<String>(),
  appendDeepNavigation<String>(),
  pushDeepNavigation<dynamic>(),
  popDeepNavigation<void>(),
  ;

  BlocEventType<T> get event => BlocEventType<T>("$this");
}

/// Helper class that that can fire events into a [BlocEventChannel]
///
/// If you are provided with a [BuildContext] you can use one of the extension functions instead.
/// All functions here have an equivalent in a BuildContext extension.
class EventNavigation {
  static void changeMainNavigation<T>(
      BlocEventChannel channel, T newMainNavigation) {
    channel.fireEvent(NavigationEvent.mainNavigation.event, newMainNavigation);
  }

  static void undoNavigation(BlocEventChannel channel) {
    channel.fireEvent(NavigationEvent.previousMainNavigation.event, null);
  }

  static void deepNavigate(
      BlocEventChannel channel, String deepNavigationString) {
    channel.fireEvent(
        NavigationEvent.deepLinkNavigation.event, deepNavigationString);
  }

  static void appendDeepNavigation(
      BlocEventChannel channel, String addedDeepNavigationString) {
    channel.fireEvent(
        NavigationEvent.appendDeepNavigation.event, addedDeepNavigationString);
  }

  static void pushDeepNavigation<T>(
      BlocEventChannel channel, T addedDeepNavigation) {
    channel.fireEvent(
        NavigationEvent.pushDeepNavigation.event, addedDeepNavigation);
  }

  static void popDeepNavigation(BlocEventChannel channel) {
    channel.fireEvent<void>(NavigationEvent.popDeepNavigation.event, null);
  }
}

extension BuildContextNavigation on BuildContext {
  void changeMainNavigation<T>(T newMainNavigation) {
    EventNavigation.changeMainNavigation(eventChannel, newMainNavigation);
  }

  void undoNavigation() {
    EventNavigation.undoNavigation(eventChannel);
  }

  void deepNavigate(String deepNavigationString) {
    EventNavigation.deepNavigate(eventChannel, deepNavigationString);
  }

  void appendDeepNavigation(String addedDeepNavigationString) {
    EventNavigation.appendDeepNavigation(
        eventChannel, addedDeepNavigationString);
  }

  void pushDeepNavigation<T>(T addedDeepNavigation) {
    EventNavigation.pushDeepNavigation(eventChannel, addedDeepNavigation);
  }

  void popDeepNavigation() {
    EventNavigation.popDeepNavigation(eventChannel);
  }

  MainNavigationBloc<T> watchNavigationBloc<T>() =>
      watchBloc<MainNavigationBloc<T>>();
  MainNavigationBloc<T> navigationBloc<T>() =>
      readBloc<MainNavigationBloc<T>>();
}
