import 'package:event_navigation/event_navigation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

enum Screen { home, blog, error }

/// Undo strategy that records the deep navigation changes it is told about.
class RecordingUndoStrategy extends UndoRedoMainNavigationStrategy<String> {
  final deepLogs = <List<Object?>>[];

  @override
  void logDeepNavigation(
    String mainNavigation,
    DeepNavigationNode<String>? oldNavigationRoot,
    DeepNavigationNode<String>? newNavigationRoot,
  ) {
    deepLogs.add([mainNavigation, oldNavigationRoot, newNavigationRoot]);
  }
}

MainNavigationBloc<Screen> buildEnumBloc({String Function(Screen)? convert}) =>
    MainNavigationBloc<Screen>(
      strategy: ListNavigationStrategy<Screen>(
        possibleNavigations: Screen.values,
        navigationOnError: Screen.error,
        convertToStringFunction: convert,
      ),
      undoStrategy: UndoRedoMainNavigationStrategy<Screen>(),
      defaultDeepNavigationStrategy: DeepNavigationStrategy.acceptEverything,
    );

void main() {
  group('changeMainNavigation', () {
    test('starts on the default navigation', () {
      expect(buildBloc().currentMainNavigation, 'home');
      expect(
          buildBloc(defaultNavigation: 'blog').currentMainNavigation, 'blog');
    });

    test('success', () {
      final bloc = buildBloc();

      expect(bloc.changeMainNavigation('blog'), NavigationResult.success);
      expect(bloc.currentMainNavigation, 'blog');
    });

    test('same navigation is not logged', () {
      final undo = UndoRedoMainNavigationStrategy<String>();
      final bloc = buildBloc(undoStrategy: undo);

      expect(bloc.changeMainNavigation('home'), NavigationResult.same);
      expect(undo.canUndo(), isFalse);
    });

    test('invalid navigation fails and goes to the error navigation', () {
      final bloc = buildBloc();

      expect(bloc.changeMainNavigation('nope'), NavigationResult.failed);
      expect(bloc.currentMainNavigation, 'error');
    });

    test('logUndo false does not log', () {
      final undo = UndoRedoMainNavigationStrategy<String>();
      final bloc = buildBloc(undoStrategy: undo);

      bloc.changeMainNavigation('blog', logUndo: false);

      expect(undo.canUndo(), isFalse);
    });
  });

  group('undo and redo', () {
    test('do nothing when there is no history', () {
      final bloc = buildBloc();

      bloc.undoNavigation();
      bloc.redoNavigation();

      expect(bloc.currentMainNavigation, 'home');
    });

    test('walk through the history', () {
      final bloc = buildBloc();
      bloc.changeMainNavigation('blog');
      bloc.changeMainNavigation('about');

      bloc.undoNavigation();
      expect(bloc.currentMainNavigation, 'blog');
      bloc.undoNavigation();
      expect(bloc.currentMainNavigation, 'home');
      bloc.redoNavigation();
      expect(bloc.currentMainNavigation, 'blog');
      bloc.redoNavigation();
      expect(bloc.currentMainNavigation, 'about');
    });
  });

  group('fullNavigation', () {
    test('fullNavigationOnMainNavigation uses that navigation\'s deep path',
        () {
      final bloc = buildBloc();
      bloc.changeMainNavigation('blog');
      bloc.pushDeepNavigation('x');
      bloc.changeMainNavigation('home');

      expect(bloc.fullNavigation, 'home');
      expect(bloc.fullNavigationOnMainNavigation('blog'), 'blog/x');
      expect(bloc.fullNavigationOnMainNavigation('about'), 'about');
    });
  });

  group('changeFullNavigation', () {
    test('valid path', () {
      final bloc = buildBloc();

      bloc.changeFullNavigation('blog/x/y', updateBloc: false);

      expect(bloc.currentMainNavigation, 'blog');
      expect(bloc.fullNavigation, 'blog/x/y');
      expect(bloc.failedLastNavigation, isFalse);
    });

    test('empty string goes to the default navigation', () {
      final bloc = buildBloc();
      bloc.changeMainNavigation('blog');

      bloc.changeFullNavigation('', updateBloc: false);

      expect(bloc.currentMainNavigation, 'home');
      expect(bloc.failedLastNavigation, isFalse);
    });

    test('unknown main navigation goes to error and is logged', () {
      final bloc = buildBloc();

      bloc.changeFullNavigation('nope/x', updateBloc: false);

      expect(bloc.currentMainNavigation, 'error');
      expect(bloc.failedLastNavigation, isTrue);
      expect(bloc.lastFailedFullNavigation, 'nope/x');
    });

    test('rejected deep navigation goes to error and is logged', () {
      final bloc = buildBloc(
        deepStrategy: DefaultListDeepNavigationStrategy<String>(
            allowedSubNavigation: ['x']),
      );

      bloc.changeFullNavigation('blog/z', updateBloc: false);

      expect(bloc.currentMainNavigation, 'error');
      expect(bloc.failedLastNavigation, isTrue);
      expect(bloc.lastFailedFullNavigation, 'blog/z');
    });

    test('a later valid navigation clears the failure flag', () {
      final bloc = buildBloc();
      bloc.changeFullNavigation('nope', updateBloc: false);

      bloc.changeFullNavigation('blog', updateBloc: false);

      expect(bloc.failedLastNavigation, isFalse);
      expect(bloc.currentMainNavigation, 'blog');
    });

    test('updates the bloc when updateBloc is true', () {
      final bloc = buildBloc();

      bloc.changeFullNavigation('about');

      expect(bloc.currentMainNavigation, 'about');
    });

    test('denies deep navigation by default', () {
      final bloc = MainNavigationBloc<String>(
        strategy: ListNavigationStrategy<String>(
            possibleNavigations: testNavigations, navigationOnError: 'error'),
        undoStrategy: UndoRedoMainNavigationStrategy<String>(),
      );

      bloc.changeFullNavigation('blog/x', updateBloc: false);

      expect(bloc.currentMainNavigation, 'error');
      expect(bloc.failedLastNavigation, isTrue);
    });
  });

  group('non-String navigation types', () {
    test('enum with custom string conversion', () {
      final bloc = buildEnumBloc(convert: (s) => s.name);

      bloc.changeFullNavigation('blog/home', updateBloc: false);

      expect(bloc.currentMainNavigation, Screen.blog);
      expect(bloc.currentDeepNavigation?.value, Screen.home);
      expect(bloc.fullNavigation, 'blog/home');
    });

    test('enum with default toString conversion', () {
      final bloc = buildEnumBloc();

      bloc.changeFullNavigation('Screen.blog', updateBloc: false);

      expect(bloc.currentMainNavigation, Screen.blog);
      expect(bloc.fullNavigation, 'Screen.blog');
    });

    test('unconvertible main segment goes to error', () {
      final bloc = buildEnumBloc(convert: (s) => s.name);

      bloc.changeFullNavigation('nope', updateBloc: false);

      expect(bloc.currentMainNavigation, Screen.error);
      expect(bloc.failedLastNavigation, isTrue);
      expect(bloc.lastFailedFullNavigation, 'nope');
    });

    test('unconvertible deep segment goes to error', () {
      final bloc = buildEnumBloc(convert: (s) => s.name);

      bloc.changeFullNavigation('blog/nope', updateBloc: false);

      expect(bloc.currentMainNavigation, Screen.error);
      expect(bloc.failedLastNavigation, isTrue);
      expect(bloc.lastFailedFullNavigation, 'blog/nope');
    });

    test('push, pop and undo work', () {
      final bloc = buildEnumBloc(convert: (s) => s.name);

      bloc.changeMainNavigation(Screen.blog);
      bloc.pushDeepNavigation(Screen.home);
      expect(bloc.fullNavigation, 'blog/home');
      bloc.popDeepNavigation();
      expect(bloc.fullNavigation, 'blog');
      bloc.undoNavigation();
      expect(bloc.currentMainNavigation, Screen.home);
    });
  });

  group('pushDeepNavigation', () {
    test('accepted values become the root and then the leaf', () {
      final bloc = buildBloc();
      bloc.changeMainNavigation('blog');

      expect(bloc.pushDeepNavigation('x'), NavigationResult.success);
      expect(bloc.currentDeepNavigation?.value, 'x');
      expect(bloc.currentDeepNavigation?.level, 0);

      expect(bloc.pushDeepNavigation('y'), NavigationResult.success);
      expect(bloc.currentDeepNavigation?.leaf.value, 'y');
      expect(bloc.currentDeepNavigation?.leaf.level, 1);
      expect(bloc.fullNavigation, 'blog/x/y');
    });

    test('is synchronous', () {
      final bloc = buildBloc();

      final result = bloc.pushDeepNavigation('x');

      expect(result, isA<NavigationResult>());
    });

    test('rejected values fail and go to the error navigation', () {
      final bloc = buildBloc(
        deepStrategy: DefaultListDeepNavigationStrategy<String>(
            allowedSubNavigation: ['x']),
      );
      bloc.changeMainNavigation('blog');

      expect(bloc.pushDeepNavigation('z'), NavigationResult.failed);
      expect(bloc.currentMainNavigation, 'error');
    });

    test('uses the strategy of the current main navigation', () {
      final bloc =
          buildBloc(deepStrategy: DeepNavigationStrategy.denyEverything)
            ..deepNavigationStrategyMap['blog'] =
                DeepNavigationStrategy.acceptEverything;

      bloc.changeMainNavigation('blog');
      expect(bloc.pushDeepNavigation('x'), NavigationResult.success);

      bloc.changeMainNavigation('about');
      expect(bloc.pushDeepNavigation('x'), NavigationResult.failed);
    });
  });

  group('popDeepNavigation', () {
    test('pops one level at a time', () {
      final bloc = buildBloc();
      bloc.pushDeepNavigation('x');
      bloc.pushDeepNavigation('y');
      expect(bloc.canPopDeepNavigation, isTrue);

      bloc.popDeepNavigation();
      expect(bloc.currentDeepNavigation?.leaf.value, 'x');

      bloc.popDeepNavigation();
      expect(bloc.currentDeepNavigation, isNull);
      expect(bloc.canPopDeepNavigation, isFalse);
    });

    test('does nothing at the base layer', () {
      final bloc = buildBloc();

      bloc.popDeepNavigation();

      expect(bloc.currentDeepNavigation, isNull);
      expect(bloc.currentMainNavigation, 'home');
    });
  });

  group('deep navigation and the undo strategy', () {
    test('push and pop are logged', () {
      final undo = RecordingUndoStrategy();
      final bloc = buildBloc(undoStrategy: undo);

      bloc.pushDeepNavigation('x');
      final node = bloc.currentDeepNavigation;
      bloc.popDeepNavigation();

      expect(undo.deepLogs, hasLength(2));
      expect(undo.deepLogs[0], ['home', null, node]);
      expect(undo.deepLogs[1], ['home', node, null]);
    });

    test('popping at the base layer is not logged', () {
      final undo = RecordingUndoStrategy();
      final bloc = buildBloc(undoStrategy: undo);

      bloc.popDeepNavigation();

      expect(undo.deepLogs, isEmpty);
    });

    test('handleDeepNavigationFromRoot logs success but not same', () {
      final undo = RecordingUndoStrategy();
      final bloc = buildBloc(undoStrategy: undo);

      expect(bloc.handleDeepNavigationFromRoot(['x', 'y']),
          NavigationResult.success);
      expect(undo.deepLogs, hasLength(1));

      expect(
          bloc.handleDeepNavigationFromRoot(['x', 'y']), NavigationResult.same);
      expect(undo.deepLogs, hasLength(1));
    });

    test('handleDeepNavigationFromRoot fails when a value is rejected', () {
      final undo = RecordingUndoStrategy();
      final bloc = buildBloc(
        undoStrategy: undo,
        deepStrategy: DefaultListDeepNavigationStrategy<String>(
            allowedSubNavigation: ['x']),
      );

      expect(bloc.handleDeepNavigationFromRoot(['x', 'z']),
          NavigationResult.failed);
      expect(undo.deepLogs, isEmpty);
      expect(bloc.currentDeepNavigation, isNull);
    });
  });

  group('events', () {
    test('events reach the bloc', () async {
      final bloc = buildBloc();
      final channel = bloc.eventChannel;

      EventNavigation.changeMainNavigation(channel, 'blog');
      await Future<void>.delayed(Duration.zero);
      expect(bloc.currentMainNavigation, 'blog');

      EventNavigation.pushDeepNavigation(channel, 'x');
      await Future<void>.delayed(Duration.zero);
      expect(bloc.fullNavigation, 'blog/x');

      EventNavigation.appendDeepNavigation(channel, 'y');
      await Future<void>.delayed(Duration.zero);
      expect(bloc.fullNavigation, 'blog/x/y');

      EventNavigation.popDeepNavigation(channel);
      await Future<void>.delayed(Duration.zero);
      expect(bloc.fullNavigation, 'blog/x');

      EventNavigation.deepNavigate(channel, 'about');
      await Future<void>.delayed(Duration.zero);
      expect(bloc.fullNavigation, 'about');

      // Deep links are not logged, so undo goes back to where the last logged
      // navigation came from.
      EventNavigation.undoNavigation(channel);
      await Future<void>.delayed(Duration.zero);
      expect(bloc.currentMainNavigation, 'home');
    });
  });
}
