import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:vibration/vibration.dart';

import '../models/app_settings.dart';

/// Plays the alarm sound in a loop and vibrates in a repeating pattern.
/// Sound options:
///  - phoneDefault: the phone's default alarm tone
///  - ringtone: the phone's own tone for a category ('alarm', 'ringtone', 'notification')
///  - file: an audio file the user picked (already copied into the app folder)
/// The system sounds use the alarm audio stream, so they ring even on silent.
class AlarmPlayer {
  final FlutterRingtonePlayer _ringtone = FlutterRingtonePlayer();
  AudioPlayer? _filePlayer;

  Future<void> start({
    required SoundMode mode,
    String? path,
    required bool vibrate,
  }) async {
    await stop();
    try {
      if (mode == SoundMode.file && path != null && File(path).existsSync()) {
        await _playFile(path);
      } else if (mode == SoundMode.ringtone) {
        await _playSystem(path ?? 'alarm');
      } else {
        await _playSystem('alarm');
      }
    } catch (_) {
      // Fall back to the default alarm tone if a custom sound fails.
      try {
        await _playSystem('alarm');
      } catch (_) {}
    }
    if (vibrate) await _startVibration();
  }

  Future<void> _playSystem(String kind) {
    switch (kind) {
      case 'ringtone':
        return _ringtone.playRingtone(looping: true, volume: 1.0, asAlarm: true);
      case 'notification':
        return _ringtone.playNotification(looping: true, volume: 1.0, asAlarm: true);
      default:
        return _ringtone.playAlarm(looping: true, volume: 1.0, asAlarm: true);
    }
  }

  Future<void> _playFile(String path) async {
    final player = AudioPlayer();
    _filePlayer = player;
    await player.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          usageType: AndroidUsageType.alarm,
          contentType: AndroidContentType.music,
          audioFocus: AndroidAudioFocus.gain,
          stayAwake: true,
        ),
        iOS: AudioContextIOS(category: AVAudioSessionCategory.playback),
      ),
    );
    await player.setReleaseMode(ReleaseMode.loop);
    await player.setVolume(1.0);
    await player.play(DeviceFileSource(path));
  }

  Future<void> _startVibration() async {
    try {
      final has = await Vibration.hasVibrator();
      if (has == true) {
        // repeat: 0 loops the pattern from the start until cancel() is called.
        await Vibration.vibrate(pattern: [0, 600, 300, 600, 300], repeat: 0);
      }
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      await _ringtone.stop();
    } catch (_) {}
    try {
      await _filePlayer?.stop();
      await _filePlayer?.dispose();
    } catch (_) {}
    _filePlayer = null;
    try {
      await Vibration.cancel();
    } catch (_) {}
  }
}
