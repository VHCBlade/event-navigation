import '../deep_navigation.dart';

/// Details how to handle undoing and redoing the navigation.
///
/// [UndoRedoMainNavigationStrategy] is the default implementation of this.
abstract class NavigationUndoStrategy<T> {
  T undoNavigation();
  T redoNavigation();
  bool canUndo();
  bool canRedo();

  void logNavigation(T oldNavigation, T newNavigation);

  /// Called whenever the deep navigation of [mainNavigation] changes. Either root is
  /// null when there was (or is now) no deep navigation.
  void logDeepNavigation(
    T mainNavigation,
    DeepNavigationNode<T>? oldNavigationRoot,
    DeepNavigationNode<T>? newNavigationRoot,
  );
}

/// Keeps a history of main navigations that can be undone and redone.
///
/// Logging a new navigation clears the redo history. Deep navigation is not tracked.
///
/// [maxHistory] limits how many undo steps are kept. The oldest are dropped first.
/// Null means unlimited.
class UndoRedoMainNavigationStrategy<T> implements NavigationUndoStrategy<T> {
  final int? maxHistory;

  final List<T> _undoStack = [];
  final List<T> _redoStack = [];
  T? _current;

  UndoRedoMainNavigationStrategy({this.maxHistory})
      : assert(maxHistory == null || maxHistory > 0);

  /// The navigation most recently logged, or the one reached by undo/redo.
  T? get currentNavigation => _current;

  /// The navigation that [undoNavigation] would go to, if any.
  T? get previousNavigation => _undoStack.isEmpty ? null : _undoStack.last;

  @override
  bool canUndo() => _undoStack.isNotEmpty;

  @override
  bool canRedo() => _redoStack.isNotEmpty;

  @override
  void logNavigation(T oldNavigation, T newNavigation) {
    _undoStack.add(oldNavigation);
    _redoStack.clear();
    _current = newNavigation;

    final max = maxHistory;
    if (max != null && _undoStack.length > max) {
      _undoStack.removeAt(0);
    }
  }

  @override
  T undoNavigation() {
    assert(canUndo());

    _redoStack.add(_current as T);
    final target = _undoStack.removeLast();
    _current = target;
    return target;
  }

  @override
  T redoNavigation() {
    assert(canRedo());

    _undoStack.add(_current as T);
    final target = _redoStack.removeLast();
    _current = target;
    return target;
  }

  @override
  void logDeepNavigation(
    T mainNavigation,
    DeepNavigationNode<T>? oldNavigationRoot,
    DeepNavigationNode<T>? newNavigationRoot,
  ) {
    // DO NOTHING
  }
}
