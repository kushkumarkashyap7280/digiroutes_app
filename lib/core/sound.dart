import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logic/providers.dart';

/// Light haptic + click feedback for key interactions, gated by the
/// user's Sound setting.
///
/// Plays a bundled click sound rather than [SystemSound.play] — the
/// latter is silent on many Android devices whenever the OS-level
/// "Touch sounds" setting is off, which made the Settings toggle feel
/// like it did nothing.
class AppSound {
  AppSound._();

  static final AudioPlayer _player = AudioPlayer()
    ..setPlayerMode(PlayerMode.lowLatency)
    ..setReleaseMode(ReleaseMode.stop);
  static bool _ready = false;

  static Future<void> _ensureReady() async {
    if (_ready) return;
    _ready = true;
    await _player.setSourceAsset('sounds/click.wav');
  }

  static void tap(WidgetRef ref) {
    if (!ref.read(soundEnabledProvider)) return;
    HapticFeedback.lightImpact();
    _ensureReady().then((_) => _player.resume());
  }
}
