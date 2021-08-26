import 'package:carousel_slider/carousel_controller.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class FullScreenCarousel extends StatefulWidget {
  final CarouselController? controller;
  final List<Widget> items;
  final Function(int)? onManualPageChange;
  final bool withSafeAreaPadding;

  const FullScreenCarousel(
      {Key? key,
      this.controller,
      this.withSafeAreaPadding = false,
      required this.items,
      this.onManualPageChange})
      : super(key: key);

  @override
  State<FullScreenCarousel> createState() => _FullScreenCarouselState();
}

class _FullScreenCarouselState extends State<FullScreenCarousel> {
  late final CarouselController controller;

  @override
  void initState() {
    super.initState();
    controller = widget.controller ?? CarouselController();
  }

  /// Calculates the aspect ratio of the currently available viewport, to make the carousel take the entire screen.
  double calculateAspectRatio(BuildContext context) {
    final data = MediaQuery.of(context);

    final topPadding = widget.withSafeAreaPadding
        ? 0
        : data.padding.top + data.viewPadding.top + data.viewInsets.top;

    final value = data.size.width /
        (data.size.height -
            topPadding -
            data.padding.left -
            data.padding.right);

    return value;
  }

  @override
  Widget build(BuildContext context) {
    return CarouselSlider(
      carouselController: controller,
      items: widget.items,
      options: CarouselOptions(
          autoPlay: false,
          viewportFraction: 1,
          enableInfiniteScroll: false,
          aspectRatio: calculateAspectRatio(context),
          enlargeCenterPage: true,
          onPageChanged: (val, CarouselPageChangedReason reason) {
            if (reason != CarouselPageChangedReason.manual) {
              return;
            }
            if (widget.onManualPageChange != null) {
              widget.onManualPageChange!(val);
            }
          }),
    );
  }
}
