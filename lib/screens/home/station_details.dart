import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sonoreapp/services/audiohandler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../logic/station.dart';
import '../../models/station.dart';

class StationDetails extends StatefulWidget {
  final Station station;
  const StationDetails({required this.station, super.key});

  @override
  State<StationDetails> createState() => _StationDetailsState();
}

class _StationDetailsState extends State<StationDetails> {
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
          image: logic.getStationImage(widget.station),
          fit: BoxFit.fitWidth,
          width: 80.0,
          height: 80.0,
        ),
      ),
    );
  }

  //
  // Delete Button
  //
  Widget _buildDeleteButton() {
    final handler = context.read<SonoreAudioHandler>();
    final bloc = context.read<StationBloc>();
    return TextButton.icon(
      onPressed: () async {
        // stop playing if necessary
        if (handler.playbackState.value.playing &&
            handler.currentUuid == widget.station.uuid) {
          handler.pause();
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

  void _updateField(String field, dynamic value) {
    final logic = context.read<StationBloc>();
    String input = value.toString();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextFormField(
                decoration: InputDecoration(
                  label: Text(field),
                ),
                initialValue: input,
                onChanged: (v) => input = v,
              ),
              const SizedBox(height: 8.0),
              TextButton(
                onPressed: () async {
                  if (field == 'Station Image URL') {
                    widget.station.image = input;
                  } else if (field == 'Tags') {
                    widget.station.info['tags'] = input;
                  }
                  await logic.updateStation(widget.station);
                  if (context.mounted) {
                    Navigator.pop(context);
                    setState(() {});
                  }
                },
                child: const Text('update'),
              )
            ],
          ),
        );
      },
    );
  }

  ListTile _buildStationName() {
    final style = TextStyle(color: Theme.of(context).colorScheme.tertiary);
    return ListTile(
      title: const Text('Station Name'),
      subtitle: Text(widget.station.name, style: style),
      onTap: widget.station.info["homepage"]?.isNotEmpty == true
          ? () => launchUrl(Uri.parse(widget.station.info["homepage"]))
          : null,
    );
  }

  ListTile _buildStationImage() {
    final style = TextStyle(color: Theme.of(context).colorScheme.secondary);
    return ListTile(
      title: const Text('Station Image URL'),
      subtitle: widget.station.image.isNotEmpty
          ? Text(widget.station.image, style: style)
          : Text('(Tap to enter new URL)', style: style),
      onTap: () => setState(() => _updateField(
            'Station Image URL',
            widget.station.image,
          )),
    );
  }

  ListTile _buildLocLanguage() {
    String subtitle = [
      widget.station.info["state"],
      widget.station.info["country"],
      widget.station.info["language"],
    ].join(', ');
    return ListTile(
      title: const Text('Location, Language'),
      subtitle: Text(subtitle),
    );
  }

  ListTile _buildCodecSpeed() {
    String subtitle = [
      widget.station.info["codec"],
      '${widget.station.bitrate} kbps',
    ].join(', ');
    return ListTile(
      title: const Text('Codec, Bitrate'),
      subtitle: Text(subtitle),
    );
  }

  ListTile _buildTags() {
    final style = TextStyle(color: Theme.of(context).colorScheme.secondary);
    return ListTile(
      title: const Text('Tags'),
      subtitle: widget.station.info["tags"]?.isNotEmpty == true
          ? Text(widget.station.info["tags"], style: style)
          : Text('(Tap to enter new tags)', style: style),
      onTap: () => _updateField('Tags', widget.station.info["tags"]),
    );
  }

  ListTile _buildLabels() {
    return ListTile(
      title: const Text('Categories'),
      subtitle: _buildLabelSelection(),
    );
  }

  //
  // Label Selection
  //
  Widget _buildLabelSelection() {
    final style = TextStyle(color: Theme.of(context).colorScheme.secondary);
    final bloc = context.watch<StationBloc>();
    final labels = bloc.labels;
    final selected = widget.station.labels;

    return InkWell(
      child: Text(
        selected.isEmpty ? '(Choose categories)' : selected.join(', '),
        style: style,
        // overflow: TextOverflow.ellipsis,
      ),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'Categories',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: Text(widget.station.name),
        title: const Text("Station Details"),
        actions: [_buildDeleteButton()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          shrinkWrap: true,
          children: [
            _buildStationLogo(),
            _buildStationName(),
            _buildStationImage(),
            _buildLocLanguage(),
            _buildCodecSpeed(),
            _buildTags(),
            _buildLabels(),
          ],
        ),
      ),
    );
  }
}
