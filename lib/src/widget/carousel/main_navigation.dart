import 'package:carousel_slider/carousel_controller.dart';
import 'package:event_bloc/event_bloc.dart';
import 'package:event_navigation/event_navigation.dart';
import 'package:flutter/material.dart';

class MainNavigationFullScreenCarousel<T> extends StatefulWidget {
  final List<T> navigationOptions;
  final Widget Function(BuildContext, T) navigationBuilder;
  final bool withSafeAreaPadding;

  const MainNavigationFullScreenCarousel(
      {Key? key,
      required this.navigationOptions,
      required this.navigationBuilder,
      this.withSafeAreaPadding = false})
      : super(key: key);

  @override
  _MainNavigationFullScreenCarouselState<T> createState() =>
      _MainNavigationFullScreenCarouselState<T>();
}

class _MainNavigationFullScreenCarouselState<T>
    extends State<MainNavigationFullScreenCarousel<T>> {
  late final CarouselController controller;

  @override
  void initState() {
    super.initState();
    controller = CarouselController();
  }

  @override
  Widget build(BuildContext context) {
    final navBloc = BlocProvider.watch<MainNavigationBloc<T>>(context);
    final page =
        widget.navigationOptions.indexOf(navBloc.currentMainNavigation);

    if (page >= 0) {
      Future.delayed(Duration.zero).then((_) => controller.animateToPage(page));
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
