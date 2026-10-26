# AGENTS.md

Instructions for AI agents (and humans) maintaining the `event_navigation` Flutter package.

## 1. What this package is

`event_navigation` is a navigation layer built on [`event_bloc`](https://pub.dev/packages/event_bloc). Navigation is not driven by `Navigator` routes. It is driven by events fired into a `BlocEventChannel` and handled by a single bloc, `MainNavigationBloc<T>`.

Navigation has two levels:

- **Main navigation**: one top-level value of type `T` (e.g. `home`, `blog`). Exactly one is current at any time.
- **Deep navigation**: a per-main-navigation linked list of `DeepNavigationNode<T>` (e.g. `blog/post/comments`). Each main navigation has its own deep stack.

The full navigation is serialised as a path string: `main/deep1/deep2`. This string is what the web URL fragment mirrors (`/#/main/deep1/deep2`).

- Package: `event_navigation`, current version in `pubspec.yaml` (see `CHANGELOG.md`).
- Dependencies: `event_bloc ^4.2.0`, `carousel_slider ^5.0.0`, `equatable`, `provider`, `universal_html`, Flutter SDK.
- Lints: `flutter_lints` plus the overrides in `analysis_options.yaml`.

## 2. Repository layout

```
README.md                        User-facing documentation. Keep in sync with the public API.
CHANGELOG.md                     One entry per released version.
docs/AGENTS.md                   This file.
lib/
  event_navigation.dart          Public barrel file. Every public symbol must be exported here.
  src/
    navigation.dart              MainNavigationBloc<T>, NavigationResult. The core logic.
    event.dart                   NavigationEvent enum, EventNavigation static helpers,
                                 BuildContextNavigation extension.
    deep_navigation.dart         DeepNavigationNode<T>: immutable, Equatable linked list.
    strategy/
      main_navigation.dart       MainNavigationStrategy<T>, ListNavigationStrategy<T>
      deep_navigation.dart       DeepNavigationStrategy<T>, Function- and List-based impls
      navigation_undo.dart       NavigationUndoStrategy<T>, UndoRedoMainNavigationStrategy<T>
    widget/
      widget.dart                BlocBackButton
      main_navigation.dart       MainNavigationButton, MainNavigationBar
      carousel/                  FullScreenCarousel, MainNavigationFullScreenCarousel<T>
      app/main.dart              EventNavigationApp<T> (MaterialApp.router + custom delegate)
      app/web_app.dart           WebAppNavHandler<T> (URL <-> bloc sync). NOT exported.
test/                            Unit and widget tests. See section 7.
example/                         Runnable demo app. Path-depends on the package (`path: ../`).
scripts/                         Local tooling (zip/sync helpers). Git-ignored; not part of the package.
```

## 3. Architecture

### 3.1 Event flow

1. UI calls a `BuildContext` extension (`context.changeMainNavigation(...)`) or a static `EventNavigation.*` function.
2. That fires a `NavigationEvent` (enum in `event.dart`) on the `BlocEventChannel`.
3. `MainNavigationBloc` listens for these events (registered in `_addMainNavigationListeners` and `_addDeepNavigationListeners`), mutates its state, and calls `updateBloc()` / `updateBlocOnChange(...)` so watchers rebuild.

| Event                    | Payload  | Bloc handler                                  |
|--------------------------|----------|-----------------------------------------------|
| `mainNavigation`         | `T`      | `changeMainNavigation`                        |
| `previousMainNavigation` | none     | `undoNavigation`                              |
| `deepLinkNavigation`     | `String` | `changeFullNavigation`                        |
| `appendDeepNavigation`   | `String` | `changeFullNavigation("$fullNavigation/$v")`  |
| `pushDeepNavigation`     | `T`      | `pushDeepNavigation`                          |
| `popDeepNavigation`      | none     | `popDeepNavigation`                           |

`mainNavigation` and `pushDeepNavigation` use `allowDynamic: true` and cast the payload to `T` because the enum cannot carry the bloc's generic type. A wrong payload type fails at runtime with a cast error.

### 3.2 Strategies

Policy is injected, not hard-coded:

- `MainNavigationStrategy<T>`: which main navigations are valid (`attemptNavigation`), the default and error destinations, and `String <-> T` conversion. `T` does not have to be a `String`: values are written to the path with `toString()` (`convertToString`), and read back with `convertToValue`, which returns `T?`. **Null means "unknown segment" and makes the navigation fail.** `ListNavigationStrategy` matches segments against `possibleNavigations` using `convertToString`, then falls back to `val is T ? val : null`.
- `DeepNavigationStrategy<T>`: whether a sub-navigation may be added given the current `DeepNavigationNode` (null means base layer). Stored per main navigation in `MainNavigationBloc.deepNavigationStrategyMap`, falling back to `defaultDeepNavigationStrategy`.
- `NavigationUndoStrategy<T>`: undo/redo history of main navigations. `UndoRedoMainNavigationStrategy` keeps a full stack (optional `maxHistory`); logging a new navigation clears redo. The bloc also reports deep navigation changes through `logDeepNavigation`, which the default strategy ignores.

**The default deep strategy is `denyEverything`.** A main navigation with no registered deep strategy rejects all deep navigation. This is intentional, not a bug.

### 3.3 Deep navigation nodes

`DeepNavigationNode<T>` is immutable. Every "mutation" (`setChild`, `setLeaf`, `removeLeaf`, `changeChildAtLevel`, `createCopy`) returns a new tree. `level` is the depth from the root (root = 0) and is rewritten by `setChild`. Equality is by `level`, `value`, `child` (Equatable); `handleDeepNavigationFromRoot` relies on this to return `NavigationResult.same`.

Note that deep nodes use the same `T` as the main navigation.

### 3.4 Web and app shell

- `EventNavigationApp` wraps `MaterialApp.router` with a minimal `RouterDelegate`. `setNewRoutePath` forwards the incoming location (minus its leading `/`) to `EventNavigation.deepNavigate`. On web it wraps the child in `WebAppNavHandler`.
- `WebAppNavHandler` reads `window.location.href` on init and fires `deepNavigate`. In `didChangeDependencies` it compares the URL fragment to `bloc.fullNavigation` and calls `location.assign` / `location.replace` to sync. It watches `MainNavigationBloc<T>`, where `T` is the type argument given to `EventNavigationApp<T>` / `WebAppNavHandler<T>`. **The type argument cannot be inferred and must be passed explicitly**; if it does not match the provided bloc's type, the provider lookup fails at runtime.
- The fragment marker is `_PATH = "/#/"`. `replaceNonPaths` and `redirectOnError` control history behaviour; see the doc comments before changing them.

### 3.5 Carousel widgets

- `FullScreenCarousel` wraps `CarouselSlider`. `ignoreGestures` is passed to `CarouselSlider.disableGesture` and also sets `NeverScrollableScrollPhysics` so that swiping is really blocked. `withSafeAreaPadding` wraps each item in a `SafeArea`.
- `MainNavigationFullScreenCarousel<T>` follows the bloc. `disableGesture` is forwarded to `FullScreenCarousel.ignoreGestures`. It tracks the last page it was told to show (`_lastPage`) so unrelated rebuilds don't re-animate; the first build jumps, later changes animate, and a manual swipe records the page before updating the bloc.

## 4. Behaviour notes and pitfalls

Quirks fixed in 0.8.0 (see `CHANGELOG.md`): `fullNavigationOnMainNavigation` using the wrong deep path, `changeMainNavigation` forcing a bloc update on error, `createCopy` unable to clear a child (now `clearChild`), `changeFullNavigation` being `async`, `pushDeepNavigation` returning a `Future`, `logDeepNavigation` never being called, one-step undo, unused `withSafeAreaPadding`, `Future.delayed` in the carousel, self-barrel imports, the `String`-only web handler/widgets, and the stub README.

Things to keep in mind:

1. **Deep values share `T` with main navigation.** For a non-`String` `T`, every deep value must be convertible by `convertToValue`, or the deep path will fail. `ListNavigationStrategy` only knows values in `possibleNavigations`; otherwise supply `convertToValueFunction`.
2. **Default enum `toString()` includes the type name** (`Page.blog`). Use `convertToStringFunction` (e.g. `(p) => p.name`) for clean URLs.
3. **`DeepNavigationNode.createCopy` with a null `newChild` keeps the existing child.** Use `clearChild: true` or `removeLeaf` / `setChild(null)` to drop it.
4. **Event payloads are cast to `T`** in the `mainNavigation` and `pushDeepNavigation` listeners (`allowDynamic: true`). A wrong payload type fails at runtime.
5. **Deep navigation is not undoable.** `logDeepNavigation` is called, but the default strategy ignores it.
6. **`changeMainNavigation` failing navigates to the error navigation.** It honours `shouldUpdateBloc`. The error navigation itself must be valid (asserted).
7. **`EventNavigation` and `BuildContextNavigation`** must stay in parity (every static has an extension).
8. **There is a benign import cycle** between `navigation.dart` and `event.dart`. Don't import the barrel (`package:event_navigation/event_navigation.dart`) from inside `lib/`; use relative imports.
9. **`FunctionDeepNavigationStrategy` takes a generic function** (`bool Function<T>(T, DeepNavigationNode<T>?)`), which is awkward to implement with closures. Existing behaviour; change only deliberately.
10. **SDK constraints were raised** to Dart `>=3.2.0` and Flutter `>=3.16.0` based on the APIs used (`RouteInformation.uri`, `CarouselSliderController`). They were not verified by running a build. Verify before releasing.
11. **`CarouselSlider.disableGesture`** is used by `FullScreenCarousel`. It was written against the `carousel_slider ^5.0.0` API from memory and not compiled. If the analyzer rejects it, drop that argument and rely on `scrollPhysics`.

## 5. Conventions

- **Public API**: anything intended for consumers must be exported from `lib/event_navigation.dart`. `web_app.dart` is deliberately not exported (`EventNavigationApp` uses it internally); keep it that way unless there is a reason.
- **Barrel parity for the context API**: every `EventNavigation.*` static function needs an equivalent `BuildContextNavigation` extension method, and vice versa (stated in the class doc). Keep them in sync.
- **New events**: add a value to `NavigationEvent`, an `EventNavigation` helper, a `BuildContext` extension, a listener in the bloc, and a test. Event names derive from `"$this"`, so renaming an enum value changes the event identity.
- **Immutability**: `DeepNavigationNode` stays immutable. Don't add mutable fields.
- **Tests**: behaviour changes come with tests. If you must leave something untested, add a `// TODO(tests): ...` block at the member describing what a test must cover (find them with `grep -rn "TODO(tests)" lib test`), and delete the block when the test is written.
- **Docs**: public classes and non-trivial methods get `///` doc comments. Match the existing style.
- **Style**: `dart format .` and `flutter analyze` must be clean. Lint overrides live in `analysis_options.yaml` (`avoid_function_literals_in_foreach_calls: false`, `constant_identifier_names: false`, `unnecessary_lambdas: true`).
- **Line endings**: existing files use CRLF. Preserve each file's line endings so diffs stay readable.
- **Navigation type**: don't assume `T` is a `String` anywhere in `lib/`. Convert with the strategy.
- **Generated or local files**: don't commit `build/`, `.dart_tool/`, or `scripts/`.

## 6. Commands

```bash
flutter pub get                 # install dependencies
dart format .                   # format
flutter analyze                 # lint
flutter test                    # run package tests

cd example && flutter pub get && flutter run -d chrome   # demo; use Chrome to exercise WebAppNavHandler
flutter pub publish --dry-run                            # validate before releasing
```

## 7. Testing

Tests live in `test/` and use `flutter_test`:

| File | Covers |
|---|---|
| `deep_navigation_test.dart` | `DeepNavigationNode` |
| `strategy_test.dart` | `ListNavigationStrategy`, deep strategies, `UndoRedoMainNavigationStrategy`, default conversions |
| `navigation_bloc_test.dart` | `MainNavigationBloc` (main/full/deep navigation, undo, events, enum `T`) |
| `navigation_widgets_test.dart` | `MainNavigationBar`, `MainNavigationButton`, `BlocBackButton` |
| `carousel_test.dart` | `FullScreenCarousel`, `MainNavigationFullScreenCarousel` |
| `test_utils.dart` | `buildBloc` and `blocApp` helpers |

Use `buildBloc` for unit tests and `blocApp` for widget tests. `blocApp` connects the bloc to the provider's event channel, which is required for `context.*` navigation to reach the bloc.

Known gaps (marked `TODO(tests)` where relevant):

- Listener notification is not asserted (for example `shouldUpdateBloc: false` not notifying), because there is no observation hook in the tests yet.
- `WebAppNavHandler` and `EventNavigationApp` are untested: they depend on `window.location`. Extract the URL logic into a pure function if you want coverage.
- The carousel's "no re-animation on unrelated rebuilds" behaviour is not asserted directly.

When you change behaviour, add or update a test in the same change.

## 8. Releasing

1. Make the change; add or update tests.
2. Run `dart format .`, `flutter analyze`, `flutter test`.
3. Bump `version` in `pubspec.yaml` following semver. While on `0.x`, breaking changes bump the minor version (see 0.5.0, 0.6.0), and additive changes or fixes bump the patch.
4. Add an entry at the top of `CHANGELOG.md`: `## x.y.z`, a blank line, then `* ` bullets in the past tense, matching existing entries ("Added ...", "Fixed ...", "Changed ...", "Updated ..."). A hotfix to a release uses `+N` (e.g. `0.6.4+1`).
5. Confirm the example app still builds against the change.
6. `flutter pub publish --dry-run`.

Do not publish or tag without explicit instruction from the maintainer.

## 9. Rules for agents

- Make the smallest change that solves the request. Don't refactor adjacent code unprompted.
- Don't change public signatures, event names, or the URL format (`/#/`) without flagging it as a breaking change and bumping the version accordingly.
- Report bugs found in passing. Fix them only if asked.
- If a request is ambiguous about main versus deep navigation, or about whether it targets web only, ask before implementing.
- Keep `README.md`, the doc comments, and `CHANGELOG.md` consistent with any behaviour change.
- Add or update tests with every behaviour change (section 7).
- Don't add dependencies without a clear reason; this is a small library and consumers inherit every dependency.
- Don't edit `pubspec.lock` files by hand.
