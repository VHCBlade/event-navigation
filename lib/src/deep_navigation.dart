/// This represents a level of subnavigation, usually representing a screen.
class DeepNavigationNode<T> {
  int level = 0;
  final T value;
  Future<bool> Function(T value)? shouldAcceptSubNavigation;
  final DeepNavigationNode<T>? child;

  DeepNavigationNode(this.value, {this.child});

  /// Creates a deep copy of this [DeepNavigationNode]
  DeepNavigationNode<T> createCopy() {
    final copy = DeepNavigationNode<T>(value);
    copy.level = level;
    copy.shouldAcceptSubNavigation = shouldAcceptSubNavigation;
    copy.setChild(child);

    return copy;
  }

  /// Will attempt to create a copy of this node with the child set to [newChild]
  ///
  /// Returns the resulting node if it was successful. Null if it was not allowed.
  Future<DeepNavigationNode<T>?> setChild(
      DeepNavigationNode<T>? newChild) async {
    if (newChild != null &&
        shouldAcceptSubNavigation != null &&
        await shouldAcceptSubNavigation!(newChild.value)) {
      return null;
    }
    if (newChild != null) {
      newChild.level = level + 1;
    }
    return DeepNavigationNode(value, child: newChild)..level = level;
  }

  DeepNavigationNode get leaf => child?.leaf ?? this;

  String convertNodeToString(String Function(T) converter) {
    final childString = child?.convertNodeToString(converter);
    return '/${converter(value)}${childString ?? ""}';
  }
}
