# Event Navigation

A navigation library built on [event_bloc](https://pub.dev/packages/event_bloc). Instead of pushing routes onto a `Navigator`, you fire navigation events and a single bloc, `MainNavigationBloc`, decides what the app's navigation state becomes. Your widgets watch that bloc and render accordingly.

Navigation has two levels:

- **Main navigation**: one top-level destination, such as `home` or `blog`. Exactly one is active at a time.
- **Deep navigation**: a stack of sub-destinations that belongs to a main navigation, such as `blog/post-1/comments`. Every main navigation has its own stack.

Together they form the *full navigation*, a path string like `blog/post-1/comments`. On web, the URL fragment (`/#/blog/post-1/comments`) is kept in sync with it.

## Installation

```yaml
dependencies:
  event_navigation: ^0.8.0
  event_bloc: ^4.2.0
```

Requires Dart 3.2 or newer and Flutter 3.16 or newer.

## Getting started

### 1. Create the bloc

The navigation type `T` can be a `String`, an enum, or any type that has a stable `toString()`. Values are written into the full navigation string with `toString()`.

```dart
const possibleNavigations = ['home', 'blog', 'about', 'error'];

MainNavigationBloc<String> generateNavigationBloc(BlocEventChannel? parent) {
  return MainNavigationBloc<String>(
    parentChannel: parent,
    strategy: ListNavigationStrategy(
      possibleNavigations: possibleNavigations,
      defaultNavigation: 'home',
      navigationOnError: 'error',
    ),
    undoStrategy: UndoRedoMainNavigationStrategy(),
  )..deepNavigationStrategyMap['blog'] = BlogDeepNavigationStrategy();
}
```

### 2. Provide it and use `EventNavigationApp`

`EventNavigationApp` needs the navigation type so it can find the bloc. Pass it explicitly.

```dart
BlocProvider(
  create: (_, channel) => generateNavigationBloc(channel),
  child: EventNavigationApp<String>(
    title: 'My App',
    builder: (context) => const MyScreens(),
  ),
);
```

On web, wrap content that needs overlays (such as a `Navigator`) in an `Overlay`, as the [example](example/lib/main.dart) does.

### 3. Navigate

From any `BuildContext` below the provider:

```dart
context.changeMainNavigation('blog');   // switch main navigation
context.undoNavigation();               // go back to the previous main navigation
context.pushDeepNavigation('post-1');   // add a level to the current main navigation
context.popDeepNavigation();            // remove the last level
context.deepNavigate('blog/post-1');    // set the full navigation from a path
context.appendDeepNavigation('comments'); // append a path to the current full navigation
```

Without a `BuildContext`, use the equivalent static functions on `EventNavigation` with a `BlocEventChannel`.

### 4. Read the state

```dart
final bloc = context.watchNavigationBloc<String>();
bloc.currentMainNavigation;  // 'blog'
bloc.currentDeepNavigation;  // DeepNavigationNode<String>? for the current main navigation
bloc.fullNavigation;         // 'blog/post-1'
```

## Strategies

Which navigations are allowed is decided by strategies you provide.

| Strategy | Decides | Built in |
|---|---|---|
| `MainNavigationStrategy<T>` | Valid main navigations, default and error destinations, converting to and from path segments | `ListNavigationStrategy` |
| `DeepNavigationStrategy<T>` | Whether a sub-navigation may be added to the current deep navigation | `DefaultListDeepNavigationStrategy`, `FunctionDeepNavigationStrategy`, `acceptEverything`, `denyEverything` |
| `NavigationUndoStrategy<T>` | Undo and redo of main navigation | `UndoRedoMainNavigationStrategy` |

Things to know:

- A main navigation with no deep strategy registered in `deepNavigationStrategyMap` uses `defaultDeepNavigationStrategy`, which is `denyEverything`. Register a strategy for every main navigation that supports deep navigation.
- Rejected navigations go to `navigationOnError`. The rejected path is stored in `lastFailedFullNavigation`.
- Converting a path segment back to a value is done by `MainNavigationStrategy.convertToValue`, which returns `null` for unknown segments. `ListNavigationStrategy` matches segments against `possibleNavigations`, so enums work without extra code. Deep navigation segments use the same conversion, so for a non-`String` `T` each deep value must be convertible too (for example by also being listed in `possibleNavigations`, or by providing `convertToValueFunction`).
- `UndoRedoMainNavigationStrategy` keeps a full history. Pass `maxHistory` to limit it. Deep navigation is not part of undo.

### Using an enum

```dart
enum Page { home, blog, error }

MainNavigationBloc<Page>(
  strategy: ListNavigationStrategy(possibleNavigations: Page.values),
  undoStrategy: UndoRedoMainNavigationStrategy(),
);

// URL: /#/blog
EventNavigationApp<Page>(builder: ...);
```

`Page.blog.toString()` is `Page.blog`, so by default the path segment would be `Page.blog`. To get `blog`, provide `convertToStringFunction: (p) => p.name` to the strategy.

## Widgets

- `MainNavigationBar<T>`: builder for navigation bars. It gives you the selected index and an `onTap(index)` that changes the main navigation.
- `MainNavigationButton<T>`: builder for buttons that change the main navigation.
- `BlocBackButton`: a `BackButton` that pops deep navigation. `levels` pops several levels at once.
- `FullScreenCarousel`: a full-screen `CarouselSlider` with one item per page.
- `MainNavigationFullScreenCarousel<T>`: a `FullScreenCarousel` that follows the bloc's main navigation. Swiping changes the main navigation, and changing the main navigation moves the carousel.

### Disabling swipe

```dart
MainNavigationFullScreenCarousel(
  navigationOptions: const ['home', 'blog', 'about'],
  navigationBuilder: (context, navigation) => ...,
  disableGesture: true, // navigate with a bar or buttons only
);
```

`disableGesture` is passed to `FullScreenCarousel.ignoreGestures`, which passes it to the `CarouselSlider` and stops swiping. Navigation through the bloc still moves the page.

## Events

Everything the bloc does is triggered by an event in `NavigationEvent`:

| Event | Payload | Effect |
|---|---|---|
| `mainNavigation` | `T` | Change main navigation |
| `previousMainNavigation` | none | Undo main navigation |
| `deepLinkNavigation` | `String` | Set the full navigation from a path |
| `appendDeepNavigation` | `String` | Append a path to the current full navigation |
| `pushDeepNavigation` | `T` | Add a deep navigation level |
| `popDeepNavigation` | none | Remove the last deep navigation level |

## Web

On web, `EventNavigationApp` wraps your content in `WebAppNavHandler`, which reads the path after `/#/` when the app starts and updates the address bar when navigation changes. `redirectOnError` and `replaceNonPaths` control how history entries are created; see the doc comments on `WebAppNavHandler`.

## Example

A runnable app lives in [example/](example/). Run it with `cd example && flutter run -d chrome`.

## Contributing

Maintainer and agent instructions are in [docs/AGENTS.md](docs/AGENTS.md).

## License

See [LICENSE](LICENSE).
