import 'package:flutter/material.dart';

import 'widgets/aura_task_widget.dart';

void main() {
  runApp(const AuraFlowApp());
}

class AuraFlowApp extends StatelessWidget {
  const AuraFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aura Flow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const AuraHomePage(),
    );
  }
}

class AuraHomePage extends StatelessWidget {
  const AuraHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060B1B),
      appBar: AppBar(
        title: const Text('Aura Flow'),
        backgroundColor: Colors.transparent,
      ),
      body: const Center(
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
