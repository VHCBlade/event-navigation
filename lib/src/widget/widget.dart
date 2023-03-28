import 'package:event_bloc/event_bloc_widgets.dart';
import 'package:event_navigation/event_navigation.dart';
import 'package:flutter/material.dart';

class BlocBackButton extends StatelessWidget {
  const BlocBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BackButton(
        onPressed: () =>
            context.fireEvent(NavigationEvent.popDeepNavigation.event, null));
  }
}
