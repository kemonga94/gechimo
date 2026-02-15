# Aura Flow Project (Phase 1 Step 1)

## Dart syntax explained with Java mindset
- `class AuraTaskWidget extends StatefulWidget` is like a Java class that extends a UI base class. Flutter composition replaces inheritance-heavy Swing/Android XML patterns.
- `final` fields in Dart are closest to Java `final` members: constructor-initialized immutable properties.
- `const` constructor in Dart is similar to Java immutable value object usage; it enables compile-time canonical instances when arguments are constants.
- `State<AuraTaskWidget>` acts like a strongly typed state holder (comparable to a Java inner class tied to the component instance).
- `with SingleTickerProviderStateMixin` is akin to adding an interface + default behavior to provide animation ticker capability.
- Null safety (`String? subtitle`) is like explicit Optional-like typing at the language level.

## Implemented widget
- File: `lib/widgets/aura_task_widget.dart`
- Purpose: Render a neon, blurred, gradient aura task card with subtle animation.
- Key techniques:
  1. `BoxShadow` for outer bloom.
  2. `BackdropFilter` (`ImageFilter.blur`) for glassy softness.
  3. `CustomPainter` with radial + linear gradients for center-to-edge aura and highlight sheen.
  4. `AnimationController` to shift gradient center over time, creating a living aura effect.

## How to use
```dart
AuraTaskWidget(
  title: 'Urgent Project Sync',
  subtitle: '2:00 PM',
  primaryColor: const Color(0xFFAD63FF),
  secondaryColor: const Color(0xFF42E8F5),
  glowIntensity: 0.8,
)
```
