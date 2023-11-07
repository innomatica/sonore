import 'dart:async';
import 'dart:developer';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../logic/station.dart';
import '../models/station.dart';

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
  late final StationBloc _logic;
  StreamSubscription? _subPlayerState;

  SonoreAudioHandler() {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
    _subPlayerState =
        _player.playerStateStream.listen((PlayerState state) async {
      log('playerState: ${state.playing}  ${state.processingState}');
      if (state.processingState == ProcessingState.loading) {
        log('update mediaItem:${_player.sequence}, ${_player.audioSource?.sequence}');
        mediaItem.add(_player.sequence?[_player.currentIndex ?? 0].tag);
      }
    });
  }

  Future<void> dispose() async {
    await _subPlayerState?.cancel();
    await _player.dispose();
  }

  void setLogic(StationBloc logic) => _logic = logic;

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        // MediaControl.rewind,
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        // MediaControl.stop,
        // MediaControl.fastForward,
      ],
      systemActions: const {
        // MediaAction.seek,
        // MediaAction.seekForward,
        // MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
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
    log('handler.playRadioStation: ${station.toMediaItem()}');
    // if (_player.playing) {
    //   // FIXME: this may not update notification data
    //   await pause();

    //   // this updates notification but generate platform exception
    //   // await stop();
    // }
    // this type of source does not return duration
    // debugPrint('uuid: ${station.uuid}');
    final mediaItem = station.toMediaItem();
    await stop();
    await _player.setAudioSource(
      AudioSource.uri(Uri.parse(station.url), tag: mediaItem),
    );
    queue.add([mediaItem]);
    // report new station is playing
    _logic.setCurrentStationId(station.uuid);
    await play();
  }
}
