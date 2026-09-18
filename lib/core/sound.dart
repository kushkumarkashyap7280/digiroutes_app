import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logic/providers.dart';

/// Light haptic + click feedback for key interactions, gated by the
/// user's Sound setting.
class AppSound {
  AppSound._();

  static void tap(WidgetRef ref) {
    if (!ref.read(soundEnabledProvider)) return;
    HapticFeedback.lightImpact();
    SystemSound.play(SystemSoundType.click);
  }
}
