import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AudioState {
  final bool isPlaying;
  final bool isEnabled;
  final double volume;

  AudioState({this.isPlaying = false, this.isEnabled = true, this.volume = 1.0});

  AudioState copyWith({bool? isPlaying, bool? isEnabled, double? volume}) {
    return AudioState(
      isPlaying: isPlaying ?? this.isPlaying,
      isEnabled: isEnabled ?? this.isEnabled,
      volume: volume ?? this.volume,
    );
  }
}

class AudioNotifier extends Notifier<AudioState> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  AudioState build() {
    _initPlayer();
    
    // Cleanup on dispose
    ref.onDispose(() {
      _audioPlayer.dispose();
    });
    
    return AudioState();
  }

  Future<void> _initPlayer() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);
    } catch (_) {}
  }
    

  Future<void> toggleEnabled(bool isTimerRunning) async {
    final newEnabled = !state.isEnabled;
    state = state.copyWith(isEnabled: newEnabled);
    
    if (newEnabled && isTimerRunning) {
      await _audioPlayer.play(AssetSource('audio/lofi.mp3'));
      state = state.copyWith(isPlaying: true);
    } else if (!newEnabled && state.isPlaying) {
      await _audioPlayer.pause();
      state = state.copyWith(isPlaying: false);
    }
  }

  Future<void> playIfEnabled() async {
    if (state.isEnabled && !state.isPlaying) {
      await _audioPlayer.play(AssetSource('audio/lofi.mp3'));
      state = state.copyWith(isPlaying: true);
    }
  }

  Future<void> pauseAudio() async {
    if (state.isPlaying) {
      await _audioPlayer.pause();
      state = state.copyWith(isPlaying: false);
    }
  }

  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume);
    state = state.copyWith(volume: volume);
  }

  Future<void> stopAudio() async {
    if (state.isPlaying) {
      await _audioPlayer.stop();
      state = state.copyWith(isPlaying: false);
    }
  }
}

final audioProvider = NotifierProvider<AudioNotifier, AudioState>(() {
  return AudioNotifier();
});
