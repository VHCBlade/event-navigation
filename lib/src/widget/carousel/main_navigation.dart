import 'package:carousel_slider/carousel_controller.dart';
import 'package:event_bloc/event_bloc_widgets.dart';
import 'package:event_navigation/event_navigation.dart';
import 'package:flutter/material.dart';

class MainNavigationFullScreenCarousel<T> extends StatefulWidget {
  final List<T> navigationOptions;
  final Widget Function(BuildContext, T) navigationBuilder;
  final bool withSafeAreaPadding;

  const MainNavigationFullScreenCarousel({
    Key? key,
    required this.navigationOptions,
    required this.navigationBuilder,
    this.withSafeAreaPadding = false,
  }) : super(key: key);

  @override
  State createState() => _MainNavigationFullScreenCarouselState<T>();
}

class _MainNavigationFullScreenCarouselState<T>
    extends State<MainNavigationFullScreenCarousel<T>> {
  late final CarouselController controller;
  bool initial = true;

  @override
  void initState() {
    super.initState();
    controller = CarouselController();
  }

  @override
  Widget build(BuildContext context) {
    final navBloc = context.watchBloc<MainNavigationBloc<T>>();
    final page =
        widget.navigationOptions.indexOf(navBloc.currentMainNavigation);

    if (page >= 0) {
      Future.delayed(Duration.zero).then((_) {
        if (initial) {
          controller.jumpToPage(page);
        } else {
          controller.animateToPage(page);
        }
        initial = false;
      });
    }

    return FullScreenCarousel(
      controller: controller,
      items: widget.navigationOptions
          .map((val) => widget.navigationBuilder(context, val))
          .toList(),
      onManualPageChange: (val) =>
          navBloc.changeMainNavigation(widget.navigationOptions[val]),
      withSafeAreaPadding: widget.withSafeAreaPadding,
    );
  }
}
