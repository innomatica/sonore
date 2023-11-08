import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../logic/station.dart';
import '../../models/label.dart';
import '../../models/station.dart';
import '../../services/audiohandler.dart';
import '../../services/station_api.dart';
import '../../shared/settings.dart';
import '../about/about.dart';
import '../settings/label_manager.dart';
import 'station_details.dart';
import 'widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? _sleepTimer;
  int _sleepTimeout = sleepTimeouts[0];

  //
  // Scaffold App Bar
  //
  AppBar _buildAppBar() {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sonore
          // Text(
          //   appName,
          //   style: TextStyle(
          //     fontWeight: FontWeight.w500,
          //     color: Theme.of(context).colorScheme.primary,
          //   ),
          // ),
          const SizedBox(width: 10),
          // Label
          Icon(
            Icons.label_rounded,
            size: 24,
            color: Theme.of(context).colorScheme.tertiary,
          ),
          const SizedBox(width: 10),
          _buildLabelMenu(context),
        ],
      ),
      actions: [
        _sleepTimer != null && _sleepTimer!.isActive
            ? _buildSleepTimerButton()
            : Container(),
        _buildActionMenu(),
      ],
    );
  }

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
    return Consumer<SonoreAudioHandler>(builder: (context, player, _) {
      return PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: (value) {
          if (value == 'Manage Labels') {
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
              value: "Manage Labels",
              child: Row(
                children: [
                  Icon(Icons.view_list_rounded,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  const Text('Manage Categories'),
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
    final handler = context.read<SonoreAudioHandler>();
    final logic = context.watch<StationBloc>();

    return Card(
      elevation: logic.currentStationId == station.uuid ? 16 : 0,
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
            // fontSize: 16.0,
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
                  // fontSize: 13.0,
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            : Text(
                station.info['tags'],
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: const TextStyle(
                  // fontSize: 12.0,
                  color: Colors.blueGrey,
                ),
              ),
        // play button
        trailing: buildPlayButton(handler, station),
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

  //
  // Search Dialog
  //
  Widget _buildSearchDialog() {
    final iconColor = Theme.of(context).colorScheme.tertiary;
    String? keyword;
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: 'Enter search keyword',
              hintText: 'station name or tags',
            ),
            onChanged: (text) => keyword = text,
          ),
          const SizedBox(height: 16.0),
          TextButton.icon(
            onPressed: () {
              if (keyword?.isNotEmpty == true) {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => _buildSearchResult(
                      StationApiService.searchStations({
                    'name': keyword,
                    'limit': '300',
                    'hidebroken': 'true',
                    'bitrateMin': '128'
                  })),
                );
              }
            },
            icon: Icon(Icons.search_rounded, color: iconColor),
            label: const Text('Search By Station Name'),
          ),
          TextButton.icon(
            onPressed: () {
              if (keyword?.isNotEmpty == true) {
                final params = {
                  'limit': '300',
                  'hidebroken': 'true',
                  'bitrateMin': '128'
                };
                if (keyword!.contains(',')) {
                  params['tagList'] = keyword!;
                } else {
                  params['tag'] = keyword!;
                }
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => _buildSearchResult(
                      StationApiService.searchStations(params)),
                );
              }
            },
            icon: Icon(Icons.search_rounded, color: iconColor),
            label: const Text('Search By Tag(s)'),
          ),
          const SizedBox(height: 8.0),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) =>
                    _buildSearchResult(StationApiService.getTopStations()),
              );
            },
            icon: Icon(Icons.star_border_rounded, color: iconColor),
            label: const Text('Top $maxSearchResult Stations'),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) =>
                    _buildSearchResult(StationApiService.getFavoriteStations()),
              );
            },
            icon: Icon(Icons.favorite_border_rounded, color: iconColor),
            label: const Text('Sonore Favorites'),
          ),
          TextButton.icon(
            onPressed: () {
              // Navigator.pop(context);
              Navigator.popAndPushNamed(context, '/map');
            },
            icon: Icon(Icons.map_rounded, color: iconColor),
            label: const Text('Find Station Information'),
          ),
        ],
      ),
    );
  }

  //
  // Search Result Dialog
  //
  Widget _buildSearchResult(Future<List<Station>> query) {
    final bloc = context.read<StationBloc>();
    return AlertDialog(
      content: SizedBox(
        width: double.maxFinite,
        child: FutureBuilder<List<Station>>(
          future: query,
          builder: (context, snapshot) => snapshot.hasData
              ? snapshot.data?.isNotEmpty == true
                  ? ListView.builder(
                      shrinkWrap: true,
                      itemCount: snapshot.data?.length,
                      itemBuilder: (context, index) => Card(
                        child: ListTile(
                          enabled: snapshot.data![index].state != 'registered',
                          onTap: () => bloc.addStation(snapshot.data![index]),
                          title: Text(
                            snapshot.data?[index].name ?? '',
                          ),
                          subtitle: Text(
                            snapshot.data?[index].info['tags'] ?? '',
                            maxLines: 1,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.tertiary),
                          ),
                        ),
                      ),
                    )
                  : const Center(child: Text("No Stations Found"))
              : const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(),
                  ),
                ),
        ),
      ),
    );
  }

  //
  // Floating Action Button
  //
  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () => showDialog(
        context: context,
        builder: (context) => _buildSearchDialog(),
      ),
      backgroundColor:
          Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
      child: const Icon(Icons.add),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(4.0),
        child: _buildStationList(),
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
