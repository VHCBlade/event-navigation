import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// This represents a level of subnavigation, usually representing a screen.
///
/// This is an [immutable] class.
@immutable
class DeepNavigationNode<T> extends Equatable {
  final int level;
  final T value;
  final DeepNavigationNode<T>? child;

  const DeepNavigationNode(this.value, {this.level = 0, this.child});

  /// Creates a deep copy of this [DeepNavigationNode] with any of the newValues if provided.
  ///
  /// Note that unlike [setChild], this will add the [newChild] as is.
  DeepNavigationNode<T> createCopy(
          {T? newValue, int? newLevel, DeepNavigationNode<T>? newChild}) =>
      DeepNavigationNode<T>(newValue ?? value,
          level: newLevel ?? level, child: newChild ?? child?.createCopy());

  /// Creates a copy of this [DeepNavigationNode] with the [newChild].
  DeepNavigationNode<T> setChild(DeepNavigationNode<T>? newChild) =>
      createCopy(newChild: newChild?.createCopy(newLevel: level + 1));

  /// Creates a copy of this [DeepNavigationNode] that has [newLeaf] set as the child of the current [leaf].
  DeepNavigationNode<T> setLeaf(DeepNavigationNode<T> newLeaf) {
    if (child == null) {
      return setChild(newLeaf);
    }
    return createCopy(newChild: child!.setLeaf(newLeaf));
  }

  ///
  DeepNavigationNode<T>? removeLeaf() {
    if (child == null) {
      return null;
    }
    createCopy(newChild: child!.removeLeaf());
  }

  DeepNavigationNode<T> changeChildAtLevel(
      int changeLevel, DeepNavigationNode<T> newChild) {
    if (changeLevel <= level) {
      throw ArgumentError(
          'Cannot change child at a level less than mine: $changeLevel My Level: $level)!');
    }

    if (changeLevel - 1 == level) {
      return setChild(newChild);
    }

    if (child == null) {
      throw ArgumentError(
          'No child at ${level + 1} so cannot change at $changeLevel');
    }

    return createCopy(
        newChild: child!.changeChildAtLevel(changeLevel, newChild));
  }

  DeepNavigationNode<T> get leaf => child?.leaf ?? this;

  DeepNavigationNode<T> getChildAtLevel(int searchLevel) {
    if (searchLevel > level) {
      throw ArgumentError(
          'Cannot get a child of a level higher than my level (Child Level: $searchLevel My Level: $level)!');
    }
    if (searchLevel == level) {
      return this;
    }
    if (child == null) {
      throw ArgumentError('No child at $searchLevel');
    }
    return child!.getChildAtLevel(searchLevel);
  }

  DeepNavigationNode<T> getParentOfChild(DeepNavigationNode<T> child) {
    assert(getChildAtLevel(child.level) == child);
    assert(child.level > level);
    return getChildAtLevel(child.level - 1);
  }

  String convertNodeToString(String Function(T) converter) {
    final childString = child?.convertNodeToString(converter);
    return '/${converter(value)}${childString ?? ""}';
  }

  @override
  List<Object?> get props => [level, value, child];
}
