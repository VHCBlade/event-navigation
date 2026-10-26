import 'package:carousel_slider/carousel_slider.dart';
import 'package:event_navigation/event_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

const _options = ['home', 'blog', 'about'];
const _swipeToNext = Offset(-500, 0);

Widget _screen(BuildContext context, String navigation) =>
    Center(child: Text(navigation));

/// The horizontal position of the center of the text. 400 means it fills the screen.
double _centerX(WidgetTester tester, String text) =>
    tester.getCenter(find.text(text)).dx;

void main() {
  group('FullScreenCarousel', () {
    Widget carousel({
      bool ignoreGestures = false,
      CarouselSliderController? controller,
      void Function(int)? onManualPageChange,
    }) =>
        MaterialApp(
          home: FullScreenCarousel(
            controller: controller,
            ignoreGestures: ignoreGestures,
            onManualPageChange: onManualPageChange,
            items: const [
              Center(child: Text('a')),
              Center(child: Text('b')),
            ],
          ),
        );

    testWidgets('swiping reports a manual page change', (tester) async {
      final pages = <int>[];
      await tester.pumpWidget(carousel(onManualPageChange: pages.add));

      await tester.drag(find.byType(CarouselSlider), _swipeToNext);
      await tester.pumpAndSettle();

      expect(pages, [1]);
      expect(_centerX(tester, 'b'), closeTo(400, 1));
    });

    testWidgets('ignoreGestures blocks swiping', (tester) async {
      final pages = <int>[];
      await tester.pumpWidget(
        carousel(ignoreGestures: true, onManualPageChange: pages.add),
      );

      await tester.drag(find.byType(CarouselSlider), _swipeToNext);
      await tester.pumpAndSettle();

      expect(pages, isEmpty);
      expect(_centerX(tester, 'a'), closeTo(400, 1));
    });

    testWidgets('ignoreGestures still allows the controller', (tester) async {
      final controller = CarouselSliderController();
      final pages = <int>[];
      await tester.pumpWidget(
        carousel(
          ignoreGestures: true,
          controller: controller,
          onManualPageChange: pages.add,
        ),
      );

      controller.animateToPage(1);
      await tester.pumpAndSettle();

      expect(_centerX(tester, 'b'), closeTo(400, 1));
      // Moved by the controller, not manually.
      expect(pages, isEmpty);
    });

    testWidgets('withSafeAreaPadding wraps items in a SafeArea',
        (tester) async {
      Widget build(bool withSafeAreaPadding) => MaterialApp(
            home: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(padding: const EdgeInsets.only(top: 50)),
                child: FullScreenCarousel(
                  withSafeAreaPadding: withSafeAreaPadding,
                  items: const [
                    Align(
                      alignment: Alignment.topLeft,
                      child: SizedBox(key: Key('item'), width: 10, height: 10),
                    ),
                  ],
                ),
              ),
            ),
          );

      await tester.pumpWidget(build(false));
      expect(tester.getTopLeft(find.byKey(const Key('item'))).dy, 0);

      await tester.pumpWidget(build(true));
      expect(tester.getTopLeft(find.byKey(const Key('item'))).dy, 50);
    });
  });

  group('MainNavigationFullScreenCarousel', () {
    Widget carousel({
      required void Function(MainNavigationBloc<String>) onBloc,
      String defaultNavigation = 'home',
      bool disableGesture = false,
    }) =>
        blocApp(
          onBloc: onBloc,
          defaultNavigation: defaultNavigation,
          child: MainNavigationFullScreenCarousel<String>(
            navigationOptions: _options,
            navigationBuilder: _screen,
            disableGesture: disableGesture,
          ),
        );

    testWidgets('shows the current navigation', (tester) async {
      await tester.pumpWidget(carousel(onBloc: (_) {}));
      await tester.pumpAndSettle();

      expect(_centerX(tester, 'home'), closeTo(400, 1));
    });

    testWidgets('starts on a non-first navigation without animating',
        (tester) async {
      await tester.pumpWidget(
        carousel(onBloc: (_) {}, defaultNavigation: 'blog'),
      );
      // One pump runs the post-frame jump, the next renders it. No settling.
      await tester.pump();
      await tester.pump();

      expect(_centerX(tester, 'blog'), closeTo(400, 1));
    });

    testWidgets('follows the bloc', (tester) async {
      late MainNavigationBloc<String> bloc;
      await tester.pumpWidget(carousel(onBloc: (b) => bloc = b));
      await tester.pumpAndSettle();

      bloc.changeMainNavigation('about');
      await tester.pumpAndSettle();

      expect(_centerX(tester, 'about'), closeTo(400, 1));
    });

    testWidgets('swiping updates the bloc', (tester) async {
      late MainNavigationBloc<String> bloc;
      await tester.pumpWidget(carousel(onBloc: (b) => bloc = b));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(CarouselSlider), _swipeToNext);
      await tester.pumpAndSettle();

      expect(bloc.currentMainNavigation, 'blog');
      expect(_centerX(tester, 'blog'), closeTo(400, 1));
    });

    testWidgets('disableGesture blocks swiping but not the bloc',
        (tester) async {
      late MainNavigationBloc<String> bloc;
      await tester
          .pumpWidget(carousel(onBloc: (b) => bloc = b, disableGesture: true));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(CarouselSlider), _swipeToNext);
      await tester.pumpAndSettle();
      expect(bloc.currentMainNavigation, 'home');
      expect(_centerX(tester, 'home'), closeTo(400, 1));

      bloc.changeMainNavigation('blog');
      await tester.pumpAndSettle();
      expect(_centerX(tester, 'blog'), closeTo(400, 1));
    });
  });
}
