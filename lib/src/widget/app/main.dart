import 'package:event_navigation/event_navigation.dart';
import 'package:event_navigation/src/widget/app/web_app.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class EventNavigationApp extends StatelessWidget {
  final Widget child;
  final String title;
  final ThemeData? theme;
  final ThemeData? darkTheme;
  final ThemeMode? themeMode;

  const EventNavigationApp({
    Key? key,
    required this.child,
    this.title = '',
    this.theme,
    this.darkTheme,
    this.themeMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: title,
        theme: theme,
        darkTheme: darkTheme,
        themeMode: themeMode,
        onGenerateInitialRoutes: (path) =>
            [MaterialPageRoute(builder: (_) => child)],
        onGenerateRoute: (settings) {
          if (settings.name != null) {
            EventNavigation.deepNavigate(context, settings.name!.substring(1));
          }
          return null;
        },
        builder: (_, child) =>
            kIsWeb ? WebAppNavHandler(child: child!) : child!);
  }
}
