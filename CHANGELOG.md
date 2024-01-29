## 0.7.0

* Updated to work with the new default web navigation that doesn't include '/#/' in the window location
* Added replaceNonPaths to WebAppNavHandler to automatically remove default web navigations from the Undo Stack

## 0.6.6

* Added fullNavigationOnMainNavigation to MainNavigationBloc

## 0.6.5

* Added BlocBackButton levels

## 0.6.4+1

* Added BlocBackButton to exported functions

## 0.6.4

* Added Convenience Widget BlocBackButton

## 0.6.3

* Added Ability to loop FullScreenCarousels

## 0.6.2

* Fixed bug where instantiating with any navigation in the MainNavigation carousel other than the first page would cause an animation to play going to the correct navigation page.
* Changed a call to updateBlocOnFutureChange to updateBlocOnChange instead because a future is not returned.

## 0.6.1

* Added Append Deep Navigation implementation.

## 0.6.0

* Updated event_bloc to ^4.2.0. This comes with it all the breaking changes introduced in event_bloc 4.0.0.
* Changed all EventNavigation functions to apply to BlocEventChannels instead. All functions that previously accepted BuildContexts are now in an extension on BuildContext.

## 0.5.0

* Changed Deep Navigation to no longer return a future. It causes problems with deep navigation. 

## 0.4.0

* Updated event_bloc package to only accept 3.1.0 and above

## 0.3.1

* Updated event_bloc package to accept 2.0.0 and above as well as 3.0.0 and above

## 0.3.0

* Added Linter (flutter_lints) and udpated code to abide by its guidelines
* Changed EventNavigationApp from using a child to a builder
* Fixed Web Navigation - this may require adding an Overlay Widget on top of the builder

## 0.2.0

* Updated packages to be compatible with Flutter 3!
* Web Navigation may be broken. This will need to be investigated

## 0.1.2

* Added ThemeMode to EventNavigationApp

## 0.1.1

* Added Description to Readme
* Added Homepage (github repo)

## 0.1.0

* Initial Release
