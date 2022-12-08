import 'package:event_bloc/event_bloc_widgets.dart';
import 'package:event_navigation/event_navigation.dart';
import 'package:flutter/widgets.dart';
import 'package:universal_html/html.dart';

const _PATH = "/#/";

/// Adds NavigationHandling to App
class WebAppNavHandler extends StatefulWidget {
  final Widget child;
  final bool redirectOnError;

  const WebAppNavHandler(
      {super.key, required this.child, this.redirectOnError = false});

  @override
  State createState() => _WebAppNavHandlerState();
}

class _WebAppNavHandlerState extends State<WebAppNavHandler> {
  /// This handles changing the navigation based on the value of the url used.
  @override
  void initState() {
    super.initState();
    final href = window.location.href;
    final path = href.substring(href.indexOf(_PATH) + _PATH.length);

    context.deepNavigate(path);
  }

  /// This handles changing the web address when an internal navigation occurs.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bloc = BlocProvider.watch<MainNavigationBloc<String>>(context);

    final href = window.location.href;
    final path = href.substring(href.indexOf(_PATH) + _PATH.length);

    final fullNavigation = bloc.fullNavigation;
    // Skip if the path is the same.
    if (path == fullNavigation) {
      return;
    }

    // Skip if the path is an error
    if (!widget.redirectOnError &&
        bloc.failedLastNavigation &&
        path == bloc.lastFailedFullNavigation) {
      return;
    }

    final newPath =
        href.substring(0, href.indexOf(_PATH) + _PATH.length) + fullNavigation;

    window.location.assign(newPath);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
