/// Details how to handle undoing and redoing the navigation.
///
/// [UndoRedoMainNavigationStrategy] is the default implementation of this.
abstract class MainNavigationUndoStrategy<T> {
  T undoNavigation();
  T redoNavigation();
  bool canUndo();
  bool canRedo();

  void logNavigation(T oldNavigation, T newNavigation);
}

class UndoRedoMainNavigationStrategy<T>
    implements MainNavigationUndoStrategy<T> {
  T? currentNavigation;
  T? previousNavigation;

  @override
  bool canRedo() => canUndo();

  @override
  bool canUndo() => previousNavigation != null;

  @override
  void logNavigation(T oldNavigation, T newNavigation) {
    previousNavigation = oldNavigation;
    currentNavigation = newNavigation;
  }

  @override
  T redoNavigation() => undoNavigation();

  @override
  T undoNavigation() {
    assert(canUndo());

    final temp = currentNavigation;
    currentNavigation = previousNavigation;
    previousNavigation = temp;

    return currentNavigation!;
  }
}
