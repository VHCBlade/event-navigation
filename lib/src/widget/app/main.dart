import 'package:event_bloc/event_bloc_widgets.dart';
import 'package:event_navigation/event_navigation.dart';
import 'package:event_navigation/src/widget/app/web_app.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class EventNavigationApp extends StatelessWidget {
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
      routerDelegate: _Delegate(builder, context.eventChannel),
      routeInformationParser: _Parser(),
    );
  }
}

class _Parser extends RouteInformationParser<Object> {
  @override
  Future<Object> parseRouteInformation(
      RouteInformation routeInformation) async {
    return routeInformation.location ?? "/";
  }
}

class _Delegate extends RouterDelegate<Object> {
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
        ? WebAppNavHandler(child: builder(context))
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
