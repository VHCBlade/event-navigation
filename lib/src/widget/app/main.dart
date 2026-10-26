import 'package:event_bloc/event_bloc_widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../event.dart';
import 'web_app.dart';

/// Creates a [MaterialApp.router] that is driven by the [MainNavigationBloc].
///
/// [T] must be the type of the [MainNavigationBloc] provided above this widget. It cannot
/// be inferred, so pass it explicitly, e.g. `EventNavigationApp<String>(...)`. It is used on
/// web to keep the URL in sync with the bloc.
class EventNavigationApp<T> extends StatelessWidget {
  final Widget Function(BuildContext) builder;
  final String title;
  final ThemeData? theme;
  final ThemeData? darkTheme;
  final ThemeMode? themeMode;

  const EventNavigationApp({
    Key? key,
    required this.builder,
    this.title = '',
    this.theme,
    this.darkTheme,
    this.themeMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: title,
      theme: theme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      routerDelegate: _Delegate<T>(builder, context.eventChannel),
      routeInformationParser: _Parser(),
    );
  }
}

class _Parser extends RouteInformationParser<Object> {
  @override
  Future<Object> parseRouteInformation(
      RouteInformation routeInformation) async {
    return routeInformation.uri.toString();
  }
}

class _Delegate<T> extends RouterDelegate<Object> {
  final Widget Function(BuildContext) builder;
  final BlocEventChannel eventChannel;

  _Delegate(this.builder, this.eventChannel);

  @override
  void addListener(VoidCallback listener) {
    // DO NOTHING
  }

  @override
  Widget build(BuildContext context) {
    return kIsWeb
        ? WebAppNavHandler<T>(child: builder(context))
        : builder(context);
  }

  @override
  Future<bool> popRoute() async {
    return true;
  }

  @override
  void removeListener(VoidCallback listener) {
    // DO NOTHING
  }

  @override
  Future<void> setNewRoutePath(configuration) async {
    EventNavigation.deepNavigate(eventChannel, '$configuration'.substring(1));
  }
}
