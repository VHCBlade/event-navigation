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
  });
}

DeepNavigationNode<String> get initialNode {
  var node = const DeepNavigationNode('cool');
  node = node.setLeaf(const DeepNavigationNode('mega'));
  node = node.setLeaf(const DeepNavigationNode('great'));
  node = node.setLeaf(const DeepNavigationNode('incredible'));
  return node;
}
