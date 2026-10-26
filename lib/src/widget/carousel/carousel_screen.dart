import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class FullScreenCarousel extends StatefulWidget {
  final CarouselSliderController? controller;
  final List<Widget> items;
  final Function(int)? onManualPageChange;

  /// If true, every item is wrapped in a [SafeArea].
  final bool withSafeAreaPadding;
  final bool loop;

  /// If true, the user cannot change pages by swiping. Pages can still be changed with the [controller].
  ///
  /// This is passed down to the [CarouselSlider] (as `disableGesture`) and, so that swiping is
  /// actually blocked, its scroll physics are set to [NeverScrollableScrollPhysics].
  /// Gestures inside the items themselves are not affected.
  final bool ignoreGestures;

  const FullScreenCarousel({
    Key? key,
    this.controller,
    this.withSafeAreaPadding = false,
    required this.items,
    this.onManualPageChange,
    this.loop = false,
    this.ignoreGestures = false,
  }) : super(key: key);

  @override
  State<FullScreenCarousel> createState() => _FullScreenCarouselState();
}

class _FullScreenCarouselState extends State<FullScreenCarousel> {
  late final CarouselSliderController controller;

  @override
  void initState() {
    super.initState();
    controller = widget.controller ?? CarouselSliderController();
  }

  @override
  Widget build(BuildContext context) {
    return CarouselSlider(
      carouselController: controller,
      disableGesture: widget.ignoreGestures,
      items: widget.withSafeAreaPadding
          ? widget.items.map((item) => SafeArea(child: item)).toList()
          : widget.items,
      options: CarouselOptions(
          autoPlay: false,
          viewportFraction: 1,
          enableInfiniteScroll: widget.loop,
          height: MediaQuery.of(context).size.height,
          enlargeCenterPage: true,
          scrollPhysics:
              widget.ignoreGestures ? const NeverScrollableScrollPhysics() : null,
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
