import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../logic/station.dart';
import '../../models/station.dart';
import '../../services/radio_player.dart';
import '../../services/station_api.dart';
import '../../shared/constants.dart';
import '../../shared/helpers.dart';

class StationDetails extends StatefulWidget {
  final Station station;
  const StationDetails({
    required this.station,
    Key? key,
  }) : super(key: key);

  @override
  State<StationDetails> createState() => _StationDetailsState();
}

class _StationDetailsState extends State<StationDetails> {
  static const _infoWidth = 250.0;
  static const _imageWidth = 180.0;
  static const _imageHeight = 180.0;

  //
  // Station Image
  //
  Widget _buildStationLogo() {
    final logic = context.read<StationBloc>();
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      child: Container(
        color: const Color.fromRGBO(0xff, 0xff, 0xff, 0.10),
        child: Image(
          // image: widget.station.getImage(),
          image: logic.getStationImage(widget.station),
          fit: BoxFit.fitWidth,
          width: _imageWidth,
          height: _imageHeight,
        ),
      ),
    );
  }

  //
  // Delete Button
  //
  Widget _buildDeleteButton() {
    final player = context.read<RadioPlayer>();
    final bloc = context.read<StationBloc>();
    return TextButton.icon(
      onPressed: () async {
        // stop playing if necessary
        if (player.isPlaying && player.currentUuid == widget.station.uuid) {
          player.pause();
        }
        bloc
            .deleteStation(widget.station)
            .then((_) => Navigator.of(context).pop());
      },
      icon: Icon(
        Icons.delete_rounded,
        color: Theme.of(context).colorScheme.error,
      ),
      label: Text(
        'delete',
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  //
  // Language, Bitrate, Location, Tags
  //
  Widget _buildInfoLines() {
    return SizedBox(
      width: _infoWidth,
      child: Column(
        children: [
          // Language, Bitrate, State
          Text(
            "${(CountryName.getSymbol(widget.station.info['countryCode']) ?? '')}"
            " ${widget.station.info['language']}"
            " ${widget.station.bitrate.toString()}kbps"
            " ${widget.station.info['state']}",
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.tertiary,
            ),
          ),
          const SizedBox(height: 8, width: 0),
          // Tags
          Text(
            widget.station.info['tags'],
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14.0),
          ),
        ],
      ),
    );
  }

  //
  // Label Selection
  //
  Widget _buildLabelSelection() {
    final bloc = context.watch<StationBloc>();
    final labels = bloc.labels;
    final selected = widget.station.labels;

    return SizedBox(
      width: _infoWidth,
      child: TextButton.icon(
        icon: const Icon(Icons.label_outline_rounded),
        label: Text(
          selected.isEmpty ? '(choose labels)' : selected.join(', '),
          overflow: TextOverflow.ellipsis,
        ),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => StatefulBuilder(builder: (context, setState) {
              return AlertDialog(
                title: const Text(
                  'Labels',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    // shrinkWrap: true,
                    itemCount: labels.length,
                    itemBuilder: (context, index) => CheckboxListTile(
                      dense: false,
                      value: selected.contains(labels[index].name),
                      onChanged: (value) {
                        // debugPrint('value:$value');
                        if (value == true) {
                          selected.add(labels[index].name);
                        } else {
                          selected.remove(labels[index].name);
                        }
                        // debugPrint('selected: $selected');
                        setState(() {});
                      },
                      title: Text(
                        labels[index].name,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.tertiary),
                      ),
                    ),
                  ),
                ),
                // actions: [],
              );
            }),
          ).then(
            (_) {
              // debugPrint('selected: $selected');
              widget.station.labels = selected;
              bloc.updateStation(widget.station);
            },
          );
        },
      ),
    );
  }

  //
  // Player Buttons
  //
  Widget _buildPlayerButtons() {
    final player = context.watch<RadioPlayer>();
    final isPlaying =
        player.currentUuid == widget.station.uuid && player.isPlaying;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 20),
        child: ElevatedButton(
          onPressed: () async {
            if (isPlaying) {
              await player.pause();
            } else {
              await player.playRadioStation(widget.station);
            }
          },
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(10),
          ),
          child: isPlaying
              ? const Icon(Icons.pause_rounded, size: 40)
              : const Icon(Icons.play_arrow_rounded, size: 40),
        ),
      ),
      Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          TextButton.icon(
            onPressed: null,
            icon: const Icon(Icons.ads_click_outlined),
            label: Text('${widget.station.info["clickCount"]}'),
          ),
          TextButton.icon(
            onPressed: widget.station.userData.containsKey('voted')
                ? null
                : () async {
                    await StationApiService.voteForStation(widget.station);
                    setState(() {});
                  },
            icon: const Icon(Icons.thumb_up_outlined),
            label: Text('${widget.station.votes}'),
          ),
          TextButton.icon(
            onPressed: () async {
              final uri = Uri(
                scheme: 'mailto',
                query: encodeQueryParameters({
                  'subject': 'Sharing my favorite radio station',
                  'body': _buildEmailBody(widget.station.uuid),
                }),
              );
              launchUrl(uri);
            },
            icon: const Icon(Icons.share),
            label: const Text('share'),
          ),
        ],
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Slider(
          value: player.volume,
          onChanged: (value) {
            setState(() {
              player.setVolume(value);
            });
          },
        ),
      ),
    ]);
  }

  //
  // Share Message
  //
  String _buildEmailBody(String uuid) {
    return "Hi  ,\r\n\r\nI hope you enjoy the station I have found. "
        "Bring the following UUID\r\n\r\n"
        "$uuid\r\n\r\n"
        "to the menu\r\n\r\n"
        "Add New Stations > Search by Station UUID\r\n\r\n"
        "If you don't have Sonore installed on your phone, "
        "you can download it from Google Play store:\n\n$urlPlayStore\r\n\r\n"
        "Cheers,";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.station.name),
        actions: [_buildDeleteButton()],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStationLogo(),
              const SizedBox(height: 16),
              _buildInfoLines(),
              // const SizedBox(height: 8),
              _buildLabelSelection(),
              _buildPlayerButtons(),
            ],
          ),
        ),
      ),
    );
  }
}
