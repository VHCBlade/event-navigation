import 'package:event_navigation/event_navigation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeepNavigationNode', () {
    test('leaf', () {
      final node = initialNode;

      expect(node.leaf.value, 'incredible');
      expect(node.child!.leaf.value, 'incredible');
      expect(node.leaf.leaf.value, 'incredible');
    });
    test('tryChildAtLevel', () {
      final node = initialNode;

      expect(node.tryChildAtLevel(0)?.value, 'cool');
      expect(node.tryChildAtLevel(1)?.value, 'mega');
      expect(node.tryChildAtLevel(2)?.value, 'great');
      expect(node.tryChildAtLevel(3)?.value, 'incredible');

      expect(node.tryChildAtLevel(2)?.tryChildAtLevel(3)?.value, 'incredible');
      expect(node.tryChildAtLevel(2)?.tryChildAtLevel(4)?.value, null);
      expect(node.tryChildAtLevel(2)?.tryChildAtLevel(20)?.value, null);
    });
    test('tryChildAtLevel throws for a parent level', () {
      expect(() => initialNode.child!.tryChildAtLevel(0), throwsArgumentError);
    });

    test('getChildAtLevel', () {
      final node = initialNode;

      expect(node.getChildAtLevel(2).value, 'great');
      expect(() => node.getChildAtLevel(4), throwsArgumentError);
      expect(() => node.child!.getChildAtLevel(0), throwsArgumentError);
    });

    test('getParentOfChild', () {
      final node = initialNode;

      expect(node.getParentOfChild(node.getChildAtLevel(2)).value, 'mega');
    });

    test('setLeaf assigns increasing levels', () {
      final node = initialNode;

      expect(node.level, 0);
      expect(node.child!.level, 1);
      expect(node.leaf.level, 3);
    });

    test('equality is structural', () {
      expect(initialNode, initialNode);
      expect(initialNode == initialNode.removeLeaf(), isFalse);
    });

    group('createCopy', () {
      test('keeps everything by default, as new instances', () {
        final node = initialNode;
        final copy = node.createCopy();

        expect(copy, node);
        expect(identical(copy.child, node.child), isFalse);
      });

      test('newChild is used as is', () {
        const newChild = DeepNavigationNode('new', level: 1);
        final copy = initialNode.createCopy(newChild: newChild);

        expect(identical(copy.child, newChild), isTrue);
      });

      test('newValue and newLevel', () {
        final copy = initialNode.createCopy(newValue: 'changed', newLevel: 5);

        expect(copy.value, 'changed');
        expect(copy.level, 5);
        expect(copy.child?.value, 'mega');
      });

      test('clearChild removes the child', () {
        final copy = initialNode.createCopy(clearChild: true);

        expect(copy.child, isNull);
        expect(copy.value, 'cool');
      });

      test('clearChild with newChild asserts', () {
        expect(
          () => initialNode.createCopy(
            clearChild: true,
            newChild: const DeepNavigationNode('new', level: 1),
          ),
          throwsAssertionError,
        );
      });
    });

    group('removeLeaf', () {
      test('removes only the last node', () {
        final node = initialNode.removeLeaf()!;

        expect(node.leaf.value, 'great');
        expect(node.leaf.level, 2);
      });

      test('returns null for a single node', () {
        expect(const DeepNavigationNode('only').removeLeaf(), isNull);
      });
    });

    group('changeChildAtLevel', () {
      test('replaces the node at the level and drops what was below', () {
        final node = initialNode
            .changeChildAtLevel(2, const DeepNavigationNode('new'));

        expect(node.tryChildAtLevel(1)?.value, 'mega');
        expect(node.tryChildAtLevel(2)?.value, 'new');
        expect(node.tryChildAtLevel(2)?.level, 2);
        expect(node.tryChildAtLevel(3), isNull);
      });

      test('throws for the same or a higher level', () {
        expect(
          () => initialNode
              .changeChildAtLevel(0, const DeepNavigationNode('new')),
          throwsArgumentError,
        );
      });

      test('throws when there is no child to reach the level', () {
        expect(
          () => initialNode
              .changeChildAtLevel(5, const DeepNavigationNode('new')),
          throwsArgumentError,
        );
      });
    });

    test('convertNodeToString', () {
      expect(
        initialNode.convertNodeToString((s) => s.toUpperCase()),
        '/COOL/MEGA/GREAT/INCREDIBLE',
      );
    });
  });
}

DeepNavigationNode<String> get initialNode {
  var node = const DeepNavigationNode('cool');
  node = node.setLeaf(const DeepNavigationNode('mega'));
  node = node.setLeaf(const DeepNavigationNode('great'));
  node = node.setLeaf(const DeepNavigationNode('incredible'));
  return node;
}
