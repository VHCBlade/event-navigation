import 'package:event_bloc/event_bloc_widgets.dart';
import 'package:event_navigation/event_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

enum Screen { home, blog }

void main() {
  group('MainNavigationBar', () {
    Widget bar(String current) => MainNavigationBar<String>(
          currentNavigation: current,
          navigationPossibilities: const ['home', 'blog', 'about'],
          builder: (index, onTap) => Column(
            children: [
              Text('index:$index'),
              TextButton(onPressed: () => onTap(2), child: const Text('go')),
            ],
          ),
        );

    testWidgets('provides the index of the current navigation',
        (tester) async {
      late MainNavigationBloc<String> bloc;
      await tester.pumpWidget(blocApp(child: bar('blog'), onBloc: (b) => bloc = b));

      expect(find.text('index:1'), findsOneWidget);
      expect(bloc.currentMainNavigation, 'home');
    });

    testWidgets('falls back to index 0 for an unknown navigation',
        (tester) async {
      await tester.pumpWidget(blocApp(child: bar('nope'), onBloc: (_) {}));

      expect(find.text('index:0'), findsOneWidget);
    });

    testWidgets('onTap changes the main navigation', (tester) async {
      late MainNavigationBloc<String> bloc;
      await tester.pumpWidget(blocApp(child: bar('home'), onBloc: (b) => bloc = b));

      await tester.tap(find.text('go'));
      await tester.pump();

      expect(bloc.currentMainNavigation, 'about');
    });

    testWidgets('works with a non-String navigation type', (tester) async {
      late MainNavigationBloc<Screen> bloc;
      await tester.pumpWidget(
        BlocProvider(
          create: (_, channel) {
            bloc = MainNavigationBloc<Screen>(
              parentChannel: channel,
              strategy: ListNavigationStrategy<Screen>(
                  possibleNavigations: Screen.values),
              undoStrategy: UndoRedoMainNavigationStrategy<Screen>(),
            );
            return bloc;
          },
          child: MaterialApp(
            home: Scaffold(
              body: MainNavigationBar<Screen>(
                currentNavigation: Screen.home,
                navigationPossibilities: Screen.values,
                builder: (index, onTap) => TextButton(
                  onPressed: () => onTap(1),
                  child: Text('index:$index'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('index:0'));
      await tester.pump();

      expect(bloc.currentMainNavigation, Screen.blog);
    });
  });

  group('MainNavigationButton', () {
    testWidgets('fires the navigation', (tester) async {
      late MainNavigationBloc<String> bloc;
      await tester.pumpWidget(
        blocApp(
          onBloc: (b) => bloc = b,
          child: MainNavigationButton<String>(
            navigation: 'blog',
            builder: (navigate) =>
                TextButton(onPressed: navigate, child: const Text('go')),
          ),
        ),
      );

      await tester.tap(find.text('go'));
      await tester.pump();

      expect(bloc.currentMainNavigation, 'blog');
    });
  });

  group('BlocBackButton', () {
    Future<MainNavigationBloc<String>> pumpWithDepth(
      WidgetTester tester,
      int levels,
    ) async {
      late MainNavigationBloc<String> bloc;
      await tester.pumpWidget(
        blocApp(
          onBloc: (b) => bloc = b,
          child: Center(child: BlocBackButton(levels: levels)),
        ),
      );
      bloc.pushDeepNavigation('a');
      bloc.pushDeepNavigation('b');
      bloc.pushDeepNavigation('c');
      await tester.pump();
      return bloc;
    }

    testWidgets('pops one level by default', (tester) async {
      final bloc = await pumpWithDepth(tester, 1);

      await tester.tap(find.byType(BackButton));
      await tester.pump();

      expect(bloc.fullNavigation, 'home/a/b');
    });

    testWidgets('pops several levels', (tester) async {
      final bloc = await pumpWithDepth(tester, 2);

      await tester.tap(find.byType(BackButton));
      await tester.pump();

      expect(bloc.fullNavigation, 'home/a');
    });
  });
}
