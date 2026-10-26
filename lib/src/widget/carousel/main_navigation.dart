import 'package:carousel_slider/carousel_slider.dart';
import 'package:event_bloc/event_bloc_widgets.dart';
import 'package:flutter/material.dart';

import '../../navigation.dart';
import 'carousel_screen.dart';

class MainNavigationFullScreenCarousel<T> extends StatefulWidget {
  final List<T> navigationOptions;
  final Widget Function(BuildContext, T) navigationBuilder;
  final bool withSafeAreaPadding;

  /// If true, the user cannot swipe between the navigation options. Navigating with the
  /// [MainNavigationBloc] (buttons, navigation bars, deep links) still changes the page.
  ///
  /// This is passed down to [FullScreenCarousel.ignoreGestures].
  final bool disableGesture;

  const MainNavigationFullScreenCarousel({
    Key? key,
    required this.navigationOptions,
    required this.navigationBuilder,
    this.withSafeAreaPadding = false,
    this.disableGesture = false,
  }) : super(key: key);

  @override
  State createState() => _MainNavigationFullScreenCarouselState<T>();
}

class _MainNavigationFullScreenCarouselState<T>
    extends State<MainNavigationFullScreenCarousel<T>> {
  late final CarouselSliderController controller;

  /// The page the carousel was last told to show, so unrelated rebuilds don't move it again.
  int? _lastPage;

  @override
  void initState() {
    super.initState();
    controller = CarouselSliderController();
  }

  @override
  Widget build(BuildContext context) {
    final navBloc = context.watchBloc<MainNavigationBloc<T>>();
    final page =
        widget.navigationOptions.indexOf(navBloc.currentMainNavigation);

    if (page >= 0 && page != _lastPage) {
      final isInitial = _lastPage == null;
      _lastPage = page;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        if (isInitial) {
          controller.jumpToPage(page);
        } else {
          controller.animateToPage(page);
        }
      });
    }

    return FullScreenCarousel(
      controller: controller,
      items: widget.navigationOptions
          .map((val) => widget.navigationBuilder(context, val))
          .toList(),
      onManualPageChange: (val) {
        _lastPage = val;
        navBloc.changeMainNavigation(widget.navigationOptions[val]);
      },
      withSafeAreaPadding: widget.withSafeAreaPadding,
      ignoreGestures: widget.disableGesture,
    );
  }
}
