import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class FullScreenCarousel extends StatefulWidget {
  final CarouselController? controller;
  final List<Widget> items;
  final Function(int)? onManualPageChange;
  final bool withSafeAreaPadding;

  const FullScreenCarousel({
    Key? key,
    this.controller,
    this.withSafeAreaPadding = false,
    required this.items,
    this.onManualPageChange,
  }) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    return CarouselSlider(
      carouselController: controller,
      items: widget.items,
      options: CarouselOptions(
          autoPlay: false,
          viewportFraction: 1,
          enableInfiniteScroll: false,
          height: MediaQuery.of(context).size.height,
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
