import 'package:event_bloc/event_bloc_widgets.dart';
import 'package:event_navigation/event_navigation.dart';
import 'package:event_navigation_example/bloc.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_, channel) => generateNavigationBloc(channel),
      child: _InnerApp(),
    );
  }
}

class _InnerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EventNavigationApp(
      title: 'VHCBlade',
      builder: (_) => Overlay(
        initialEntries: [
          OverlayEntry(
            builder: (context) => Navigator(
              onGenerateRoute: (_) => MaterialPageRoute(
                builder: (_) => const MainScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.watchBloc<MainNavigationBloc<String>>();
    final navigationBar = MainNavigationBar(
      currentNavigation: bloc.currentMainNavigation,
      navigationPossibilities: const ['home', 'blog', 'apps', 'about'],
      builder: (index, onTap) => BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: index,
        onTap: onTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Blog'),
          BottomNavigationBarItem(icon: Icon(Icons.push_pin), label: 'Apps'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'About'),
        ],
      ),
    );
    return Scaffold(
      bottomNavigationBar: navigationBar,
      body: const MainTransferScreen(),
    );
  }
}

class MainTransferScreen extends StatelessWidget {
  const MainTransferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (context.watchNavigationBloc<String>().currentMainNavigation ==
        'error') {
      return const Text('An unexpected error has occurred');
    }
    return MainNavigationFullScreenCarousel(
      navigationOptions: const ['home', 'blog', 'apps', 'about'],
      navigationBuilder: (_, navigation) {
        switch (navigation) {
          case 'home':
            return Container(color: const Color(0xFFFF0000));
          case 'blog':
            return Container(
              color: const Color(0xFF01204C),
              child: const BlogScreen(),
            );
          case 'apps':
            return Container(color: const Color(0xFF00FF00));
          case 'about':
            return Container(color: const Color(0xFF0000FF));
          default:
            return Container(color: const Color(0xFF000000));
        }
      },
    );
  }
}

class BlogScreen extends StatelessWidget {
  const BlogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.watchNavigationBloc<String>();

    if (bloc.deepNavigationMap['blog'] == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () => context.pushDeepNavigation('one'),
            child: const Text('1'),
          ),
          ElevatedButton(
            onPressed: () => context.pushDeepNavigation('two'),
            child: const Text('2'),
          ),
          ElevatedButton(
            onPressed: () => context.pushDeepNavigation('three'),
            child: const Text('3'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () => context.popDeepNavigation(),
          child: const Text('Back'),
        ),
        ElevatedButton(
          onPressed: () => context.pushDeepNavigation('one'),
          child: const Text('1'),
        ),
        ElevatedButton(
          onPressed: () => context.pushDeepNavigation('two'),
          child: const Text('2'),
        ),
      ],
    );
  }
}
