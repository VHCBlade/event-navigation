import 'package:event_bloc/event_bloc_widgets.dart';
import 'package:event_navigation/event_navigation.dart';
import 'package:flutter/widgets.dart';
import 'package:universal_html/html.dart';

const _PATH = "/#/";

/// Adds NavigationHandling to App
class WebAppNavHandler extends StatefulWidget {
  final Widget child;

  /// If true, failed navigations will redirect to an error location, thus not being added to the undo stack.
  final bool redirectOnError;

  /// If true, if the current location does not contain [_PATH], new navigations will replace the
  /// current navigation rather than add one to the Undo Stack.
  final bool replaceNonPaths;

  const WebAppNavHandler({
    super.key,
    required this.child,
    this.redirectOnError = false,
    this.replaceNonPaths = true,
  });

  @override
  State createState() => _WebAppNavHandlerState();
}

class _WebAppNavHandlerState extends State<WebAppNavHandler> {
  /// This handles changing the navigation based on the value of the url used.
  @override
  void initState() {
    super.initState();
    final href = window.location.href;
    final path = href.contains(_PATH)
        ? href.substring(href.indexOf(_PATH) + _PATH.length)
        : '';

    context.deepNavigate(path);
  }

  /// This handles changing the web address when an internal navigation occurs.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bloc = BlocProvider.watch<MainNavigationBloc<String>>(context);

    final rawHref = window.location.href;
    late final String href;
    if (!rawHref.contains(_PATH)) {
      href =
          '${rawHref.endsWith('/') ? rawHref.substring(0, rawHref.length - 1) : rawHref}$_PATH';
    } else {
      href = rawHref;
    }
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

    if (widget.replaceNonPaths && !rawHref.contains(_PATH)) {
      window.location.replace(newPath);
    } else {
      window.location.assign(newPath);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
