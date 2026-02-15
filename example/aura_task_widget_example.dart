import 'package:aura_flow/widgets/aura_task_widget.dart';
import 'package:flutter/material.dart';

class AuraTaskWidgetExample extends StatelessWidget {
  const AuraTaskWidgetExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF060B1B),
      body: Center(
        child: AuraTaskWidget(
          title: 'Workout',
          subtitle: 'Around 3 PM',
          primaryColor: Color(0xFF62FFB8),
          secondaryColor: Color(0xFF2E8BFF),
          glowIntensity: 0.85,
        ),
      ),
    );
  }
}
