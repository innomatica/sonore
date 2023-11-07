import 'package:flutter/material.dart';

import '../../models/station.dart';
import '../../services/audiohandler.dart';

StreamBuilder<bool> buildPlayButton(
    SonoreAudioHandler handler, Station station) {
  return StreamBuilder<bool>(
    stream: handler.playbackState.map((e) => e.playing).distinct(),
    builder: (context, snapshot) =>
        snapshot.data == true && handler.currentUuid == station.uuid
            ? IconButton(
                icon: const Icon(Icons.pause_rounded, size: 32),
                onPressed: () async => await handler.pause(),
              )
            : IconButton(
                icon: const Icon(Icons.play_arrow_rounded, size: 32),
                onPressed: () async => await handler.playRadioStation(station),
              ),
  );
}
