import 'package:event_bloc/event_bloc_widgets.dart';
import 'package:event_navigation/event_navigation.dart';
import 'package:flutter/material.dart';

class BlocBackButton extends StatelessWidget {
  final int levels;
  const BlocBackButton({super.key, this.levels = 1});

  @override
  Widget build(BuildContext context) {
    return BackButton(onPressed: () {
      context.fireEvent(NavigationEvent.popDeepNavigation.event, null);
      if (levels < 2) {
        return;
      }
      for (int i = 1; i < levels; i++) {
        context.fireEvent(NavigationEvent.popDeepNavigation.event, null);
      }
    });
  }
}
