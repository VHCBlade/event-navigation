// TODO Deep Navigation

/// This represents a level of subnavigation, usually representing a screen.
class DeepNavigationNode<T> {
  int level = 0;
  final T value;
  bool Function(T value)? shouldAcceptSubNavigation;
  DeepNavigationNode? _child;

  DeepNavigationNode(this.value);

  DeepNavigationNode? get child => _child;

  /// Creates a deep copy of this [DeepNavigationNode]
  DeepNavigationNode createCopy() {
    final copy = DeepNavigationNode(value);
    copy.level = level;
    copy.shouldAcceptSubNavigation = shouldAcceptSubNavigation;
    copy.setChild(child);

    return copy;
  }

  /// Will attempt to set the value of [child] if this node is willing to accept it as a subNavigation.
  ///
  /// Returns true if it was a success.
  bool setChild(DeepNavigationNode? newChild) {
    if (newChild != null &&
        shouldAcceptSubNavigation != null &&
        shouldAcceptSubNavigation!(newChild.value)) {
      return false;
    }
    _child = newChild;
    if (newChild != null) {
      newChild.level = level + 1;
    }
    return true;
  }
}
