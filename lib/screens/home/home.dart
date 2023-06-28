import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';

import '../../logic/station.dart';
import '../../models/label.dart';
import '../../models/station.dart';
import '../../services/radio_player.dart';
import '../../shared/constants.dart';
import '../../shared/settings.dart';
import '../about/about.dart';
import '../settings/label_manager.dart';
import '../settings/station_search.dart';
import 'instruction.dart';
import 'station_details.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? _sleepTimer;
  int _sleepTimeout = sleepTimeouts[0];

  //
  // Scaffold Label Menu
  //
  Widget _buildLabelMenu(BuildContext context) {
    const labelStyle = TextStyle(fontWeight: FontWeight.w600);
    final bloc = context.watch<StationBloc>();
    final labels = <StationLabel>[StationLabel.getDefault(), ...bloc.labels];

    return DropdownButton<String>(
      value: bloc.getCurrentLabel().name,
      underline: const SizedBox(height: 0),
      iconSize: 0,
      onChanged: (String? value) async {
        bloc.setCurrentLabel(labels.firstWhere(
          (e) => value == e.name,
          orElse: () => StationLabel.getDefault(),
        ));
      },
      items: labels.map<DropdownMenuItem<String>>((label) {
        return DropdownMenuItem<String>(
          value: label.name,
          child: Text(label.name, style: labelStyle),
        );
      }).toList(),
    );
  }

  //
  // Scaffold Action Menu
  //
  Widget _buildActionMenu() {
    return Consumer<RadioPlayer>(builder: (context, player, _) {
      return PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: (value) {
          if (value == 'Add New Stations') {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const StationSearch(),
            ));
            // .then((_) => setState(() {}));
          } else if (value == 'Manage Labels') {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const LabelManager(),
            ));
            // .then((_) => setState(() {}));
          } else if (value == 'Set Sleep Timer') {
            if (_sleepTimer != null) {
              _sleepTimer!.cancel();
              _sleepTimer = null;
            }
            _sleepTimer = Timer.periodic(
              const Duration(minutes: 1),
              (timer) async {
                if (timer.tick == _sleepTimeout) {
                  // timeout
                  await player.stop();
                  _sleepTimer!.cancel();
                  // _sleepTimer = null;
                }
                setState(() {});
              },
            );
            setState(() {});
          } else if (value == 'Cancel Sleep Timer') {
            if (_sleepTimer != null) {
              _sleepTimer!.cancel();
              _sleepTimer = null;
            }
            setState(() {});
          } else if (value == 'About') {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const About(),
            ));
          }
        },
        itemBuilder: (context) {
          return <PopupMenuEntry<String>>[
            PopupMenuItem(
              value: "Add New Stations",
              child: Row(
                children: [
                  Icon(Icons.cell_tower_rounded,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  const Text('Add New Stations'),
                ],
              ),
            ),
            PopupMenuItem(
              value: "Manage Labels",
              child: Row(
                children: [
                  Icon(Icons.view_list_rounded,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  const Text('Manage Labels'),
                ],
              ),
            ),
            PopupMenuItem(
              value: _sleepTimer != null && _sleepTimer!.isActive
                  ? "Cancel Sleep Timer"
                  : "Set Sleep Timer",
              child: Row(
                children: [
                  Icon(Icons.timelapse_rounded,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  _sleepTimer != null && _sleepTimer!.isActive
                      ? const Text('Cancel Sleep Timer')
                      : const Text('Set Sleep Timer'),
                ],
              ),
            ),
            PopupMenuItem(
              value: "About",
              child: Row(
                children: [
                  Icon(Icons.info_rounded,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  const Text('About'),
                ],
              ),
            ),
          ];
        },
      );
    });
  }

  //
  // Station Card
  //
  Widget _buildStationCard(Station station) {
    // debugPrint('station.name: ${station.name}');
    // debugPrint('station.labels: ${station.labels}');
    final player = context.watch<RadioPlayer>();
    final logic = context.read<StationBloc>();

    return Card(
      elevation: player.currentUuid == station.uuid ? 8 : 0,
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 8),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => StationDetails(station: station)));
        },
        leading: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          child: Container(
            color: const Color.fromRGBO(0xff, 0xff, 0xff, 0.10),
            child: Image(
              // image: station.getImage(),
              image: logic.getStationImage(station),
              fit: BoxFit.fitWidth,
              width: 60,
              height: 60,
            ),
          ),
        ),
        // title: station name
        title: Text(
          station.name,
          overflow: TextOverflow.fade,
          softWrap: false,
          style: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w400,
          ),
        ),
        // subtitle: labels or tags
        subtitle: station.labels.isNotEmpty
            ? Text(
                station.labels.join(', '),
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: TextStyle(
                  fontSize: 13.0,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              )
            : Text(
                station.info['tags'],
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: const TextStyle(
                  fontSize: 12.0,
                  color: Colors.blueGrey,
                ),
              ),

        // play button
        trailing: player.currentUuid == station.uuid && player.isPlaying
            ? IconButton(
                icon: const Icon(Icons.pause_rounded, size: 32),
                onPressed: () async {
                  await player.pause();
                },
              )
            : IconButton(
                icon: const Icon(Icons.play_arrow_rounded, size: 32),
                onPressed: () async {
                  await player.playRadioStation(station);
                },
              ),
      ),
    );
  }

  //
  // Sleep Timer Button
  //
  Widget _buildSleepTimerButton() {
    return TextButton.icon(
      onPressed: () {
        int index = sleepTimeouts.indexOf(_sleepTimeout);
        index = (index + 1) % sleepTimeouts.length;
        _sleepTimeout = sleepTimeouts[index];
        setState(() {});
      },
      icon: const Icon(Icons.timelapse_rounded),
      label: Text((_sleepTimeout - _sleepTimer!.tick).toString()),
    );
  }

  //
  // Station List
  //
  Widget _buildStationList() {
    final bloc = context.watch<StationBloc>();
    final stations = bloc.stations;
    final currentLabel = bloc.getCurrentLabel();
    // debugPrint('buildStationList: $stations');
    return stations.isEmpty
        ? currentLabel.name == allStations
            ? const FirstTime()
            : const EmptyList()
        : ListView.builder(
            itemCount: stations.length,
            itemBuilder: (context, index) => _buildStationCard(stations[index]),
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sonore
            Text(
              appName,
              style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 10),
            // Label
            Icon(
              Icons.label_outline_rounded,
              size: 20,
              color: Theme.of(context).colorScheme.tertiary,
            ),
            const SizedBox(width: 5),
            _buildLabelMenu(context),
          ],
        ),
        actions: [
          _sleepTimer != null && _sleepTimer!.isActive
              ? _buildSleepTimerButton()
              : Container(),
          _buildActionMenu(),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(4.0),
        child: _buildStationList(),
      ),
    );
  }
}
