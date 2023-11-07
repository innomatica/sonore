import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../models/station.dart';
import '../shared/constants.dart';
import '../shared/settings.dart';

Future<SonoreAudioHandler> createAudioHandler() {
  return AudioService.init(
    builder: () => SonoreAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.innomatic.sonore.channel.audio',
      androidNotificationChannelName: 'Sonore playback',
      androidNotificationOngoing: true,
      androidNotificationIcon: 'drawable/app_icon',
    ),
  );
}

class SonoreAudioHandler extends BaseAudioHandler {
  final _player = AudioPlayer();

  SonoreAudioHandler() {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
  }

  Future<void> dispose() async {
    await _player.dispose();
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.rewind,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.fastForward,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  double get volume => _player.volume;

  String? get currentUuid => _player.sequence?[0].tag.extras?['uuid'];

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
  }

  Future<void> playRadioStation(Station station) async {
    if (_player.playing) {
      // FIXME: this may not update notification data
      await pause();

      // this updates notification but generate platform exception
      // await stop();
    }
    // this type of source does not return duration
    // debugPrint('uuid: ${station.uuid}');
    await _player.setAudioSource(
      AudioSource.uri(
        Uri.parse(station.url),
        tag: MediaItem(
          id: station.uuid,
          title: appName,
          album: station.name,
          // artUri: Uri.parse(urlDefalutArt),
          // FIXME: due to the notification issue, this may not work
          artUri: station.image.isNotEmpty
              ? Uri.tryParse(station.image)
              : Uri.parse(urlDefalutArt),
        ),
      ),
    );
    await play();
  }
}
