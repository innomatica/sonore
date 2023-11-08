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

//
// Instruction: Start
//
class FirstTime extends StatelessWidget {
  const FirstTime({super.key});

  @override
  Widget build(BuildContext context) {
    // const textStyle = TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 200,
            child: Image(image: AssetImage('assets/images/sound_512.png')),
          ),
          Text(
            'Add New Stations and Start Listening',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              // fontSize: 18.0,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

//
// Instruction: No Stations for the label
//
class EmptyList extends StatelessWidget {
  const EmptyList({super.key});

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('No stations under this category',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              )),
          const SizedBox(height: 16.0, width: 0.0),
          const Text('Tap stations and change categories', style: textStyle),
          //   const SizedBox(height: 8.0, width: 0.0),
          //   const Text('and choose categories(s) for the station',
          //       style: textStyle),
        ],
      ),
    );
  }
}
