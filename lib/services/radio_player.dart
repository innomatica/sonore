import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:sonoreapp/shared/settings.dart';

import '../models/station.dart';
import '../shared/constants.dart';

class RadioPlayer extends ChangeNotifier {
  late final AudioPlayer _player;
  late final StreamSubscription? _sub;
  String? currentUuid;
  bool isPlaying = false;

  RadioPlayer() {
    _player = AudioPlayer();
    _sub = _player.playingStream.listen((event) {
      currentUuid = currentStationId();
      isPlaying = event;
      notifyListeners();
    });
  }

  @override
  dispose() {
    _sub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> play() async {
    return _player.play();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  double get volume {
    return _player.volume;
  }

  Future<void> setVolume(double volume) async {
    _player.setVolume(volume);
  }

  Future<void> stop() async {
    // streams should be closed first
    await _player.stop();
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

  String? currentStationId() {
    if (_player.audioSource?.sequence[0].tag != null) {
      return _player.audioSource?.sequence[0].tag.id;
    }
    return null;
  }

  bool isCurrentStation(String uuid) {
    if (_player.audioSource?.sequence[0].tag != null &&
        _player.audioSource?.sequence[0].tag.id == uuid) {
      return true;
    }
    return false;
  }
}
