import 'package:event_navigation/event_navigation.dart';
import 'package:flutter_test/flutter_test.dart';

enum Screen { home, blog, error }

void main() {
  group('MainNavigationStrategy defaults', () {
    test('defaultConvert uses toString', () {
      expect(MainNavigationStrategy.defaultConvert<int>(5), '5');
      expect(MainNavigationStrategy.defaultConvert(Screen.blog), 'Screen.blog');
    });

    test('defaultStringToValue only works for strings', () {
      expect(MainNavigationStrategy.defaultStringToValue<String>('a'), 'a');
      expect(MainNavigationStrategy.defaultStringToValue<Object>('a'), 'a');
      expect(MainNavigationStrategy.defaultStringToValue<int>('5'), isNull);
      expect(MainNavigationStrategy.defaultStringToValue<Screen>('blog'),
          isNull);
    });
  });

  group('ListNavigationStrategy', () {
    test('defaults to the first navigation', () {
      final strategy = ListNavigationStrategy<String>(
          possibleNavigations: ['a', 'b', 'c']);

      expect(strategy.defaultNavigation, 'a');
      expect(strategy.navigationOnError, 'a');
    });

    test('uses provided default and error navigations', () {
      final strategy = ListNavigationStrategy<String>(
        possibleNavigations: ['a', 'b', 'c'],
        defaultNavigation: 'b',
        navigationOnError: 'c',
      );

      expect(strategy.defaultNavigation, 'b');
      expect(strategy.navigationOnError, 'c');
    });

    test('requires at least one navigation', () {
      expect(
        () => ListNavigationStrategy<String>(possibleNavigations: []),
        throwsAssertionError,
      );
    });

    test('attemptNavigation', () {
      final strategy =
          ListNavigationStrategy<String>(possibleNavigations: ['a', 'b']);

      expect(strategy.attemptNavigation('a'), isTrue);
      expect(strategy.attemptNavigation('z'), isFalse);
    });

    test('strings are matched and unknown strings are passed through', () {
      final strategy =
          ListNavigationStrategy<String>(possibleNavigations: ['a', 'b']);

      expect(strategy.convertToValue('a'), 'a');
      // Rejected later by attemptNavigation, not by conversion.
      expect(strategy.convertToValue('z'), 'z');
    });

    test('enums are matched with toString by default', () {
      final strategy = ListNavigationStrategy<Screen>(
          possibleNavigations: Screen.values);

      expect(strategy.convertToString(Screen.blog), 'Screen.blog');
      expect(strategy.convertToValue('Screen.blog'), Screen.blog);
      expect(strategy.convertToValue('blog'), isNull);
    });

    test('custom convertToStringFunction is used for matching', () {
      final strategy = ListNavigationStrategy<Screen>(
        possibleNavigations: Screen.values,
        convertToStringFunction: (s) => s.name,
      );

      expect(strategy.convertToString(Screen.blog), 'blog');
      expect(strategy.convertToValue('blog'), Screen.blog);
      expect(strategy.convertToValue('Screen.blog'), isNull);
    });

    test('custom convertToValueFunction takes priority', () {
      final strategy = ListNavigationStrategy<Screen>(
        possibleNavigations: Screen.values,
        convertToValueFunction: (s) => s == 'b' ? Screen.blog : null,
      );

      expect(strategy.convertToValue('b'), Screen.blog);
      expect(strategy.convertToValue('Screen.blog'), isNull);
    });
  });

  group('DeepNavigationStrategy', () {
    test('acceptEverything and denyEverything', () {
      expect(
          DeepNavigationStrategy.acceptEverything
              .shouldAcceptNavigation('a', null),
          isTrue);
      expect(
          DeepNavigationStrategy.denyEverything
              .shouldAcceptNavigation('a', null),
          isFalse);
    });

    test('DefaultListDeepNavigationStrategy', () {
      final strategy = DefaultListDeepNavigationStrategy<String>(
          allowedSubNavigation: ['a', 'b']);

      expect(strategy.shouldAcceptNavigation('a', null), isTrue);
      expect(strategy.shouldAcceptNavigation('z', null), isFalse);
    });

    test('FunctionDeepNavigationStrategy passes the root to the function', () {
      DeepNavigationNode? received;
      final strategy = FunctionDeepNavigationStrategy<String>(<T>(value, root) {
        received = root;
        return true;
      });
      const root = DeepNavigationNode<String>('root');

      expect(strategy.shouldAcceptNavigation('a', root), isTrue);
      expect(received, root);
    });
  });

  group('UndoRedoMainNavigationStrategy', () {
    test('starts with nothing to undo or redo', () {
      final strategy = UndoRedoMainNavigationStrategy<String>();

      expect(strategy.canUndo(), isFalse);
      expect(strategy.canRedo(), isFalse);
      expect(strategy.currentNavigation, isNull);
      expect(strategy.previousNavigation, isNull);
    });

    test('supports multiple undos and redos', () {
      final strategy = UndoRedoMainNavigationStrategy<String>()
        ..logNavigation('a', 'b')
        ..logNavigation('b', 'c');

      expect(strategy.currentNavigation, 'c');
      expect(strategy.previousNavigation, 'b');

      expect(strategy.undoNavigation(), 'b');
      expect(strategy.undoNavigation(), 'a');
      expect(strategy.canUndo(), isFalse);
      expect(strategy.canRedo(), isTrue);

      expect(strategy.redoNavigation(), 'b');
      expect(strategy.redoNavigation(), 'c');
      expect(strategy.canRedo(), isFalse);
      expect(strategy.canUndo(), isTrue);
    });

    test('logging a navigation clears the redo history', () {
      final strategy = UndoRedoMainNavigationStrategy<String>()
        ..logNavigation('a', 'b');
      strategy.undoNavigation();
      expect(strategy.canRedo(), isTrue);

      strategy.logNavigation('a', 'c');

      expect(strategy.canRedo(), isFalse);
      expect(strategy.undoNavigation(), 'a');
    });

    test('maxHistory drops the oldest steps', () {
      final strategy = UndoRedoMainNavigationStrategy<String>(maxHistory: 2)
        ..logNavigation('a', 'b')
        ..logNavigation('b', 'c')
        ..logNavigation('c', 'd');

      expect(strategy.undoNavigation(), 'c');
      expect(strategy.undoNavigation(), 'b');
      expect(strategy.canUndo(), isFalse);
    });

    test('maxHistory must be positive', () {
      expect(() => UndoRedoMainNavigationStrategy<String>(maxHistory: 0),
          throwsAssertionError);
    });

    test('logDeepNavigation does nothing', () {
      final strategy = UndoRedoMainNavigationStrategy<String>();

      strategy.logDeepNavigation('a', null, const DeepNavigationNode('x'));

      expect(strategy.canUndo(), isFalse);
    });
  });
}
