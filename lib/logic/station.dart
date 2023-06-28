import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/label.dart';
import '../models/station.dart';
import '../services/sqlite.dart';
import '../shared/settings.dart';

class StationBloc extends ChangeNotifier {
  final _db = SqliteService();

  List<Station> _stations = <Station>[];
  List<StationLabel> _labels = <StationLabel>[];
  StationLabel? _currentLabel;
  String? appDocDirPath;

  StationBloc() {
    _initBloc();
  }
  // initialization
  Future _initBloc() async {
    // global variable: called once use many times
    final appDocDir = await getApplicationDocumentsDirectory();
    appDocDirPath = appDocDir.path;
    await restoreCurrentLabel();
    refreshStations();
    refreshLabels();
  }

  //
  // Station
  //
  List<Station> get stations {
    return _stations;
  }

  Future refreshStations() async {
    // get all stations if
    //  1. _currentLabel is null or
    //  2. _currentLabel.name is allStations
    // otherwise get stations only with current label
    _stations = _currentLabel == null || _currentLabel!.name == allStations
        ? await _db.getStations()
        : await _db.getStations(query: {
            'where': 'labels LIKE ?',
            'whereArgs': ['%${_currentLabel!.name}%'],
          });
    notifyListeners();
  }

  Future addStation(Station station) async {
    await _db.addStation(station);
    refreshStations();
  }

  Future updateStation(Station station) async {
    await _db.updateStation(station);
    refreshStations();
  }

  Future<Station> getStationById(String uuid) async {
    return _db.getStationById(uuid);
  }

  Future deleteStation(Station station) async {
    // this is to overcome the weird flutter logic effect
    station.state = 'deleted';
    // check station model getImage().
    if (station.image.isNotEmpty) {
      // delete locally stored favicon
      try {
        // debugPrint('deleting image of station: $appDocDirPath/${station.uuid}');
        final file = File('$appDocDirPath/${station.uuid}');
        file.deleteSync();
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    await _db.deleteStationById(station.uuid);
    refreshStations();
  }

  //
  // Station Image
  //

  // DO NOT make this function ASYNC
  ImageProvider getStationImage(Station station,
      {double? width, double? height}) {
    if (station.image.isNotEmpty) {
      try {
        final file = File('$appDocDirPath/${station.uuid}');
        if (file.existsSync()) {
          return FileImage(file);
        }
        // FIXME: this may be called multiple times if many stations are
        // added at the same time
        _downloadStationImage(station);
        // while download is in progress we return network image instantly
        return NetworkImage(station.image);
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return const AssetImage('assets/images/sound_512.png');
  }

  Future<bool> _downloadStationImage(Station station) async {
    // due to flutter logic, it tries to download image after deleted
    if (station.image.isNotEmpty && station.state != 'deleted') {
      debugPrint('downloadImage');
      final res = await http.get(Uri.parse(station.image));
      if (res.statusCode == 200) {
        final file = File('$appDocDirPath/${station.uuid}');
        await file.writeAsBytes(res.bodyBytes);
        return true;
      }
    }
    return false;
  }

  //
  // StationLabel
  //
  List<StationLabel> get labels {
    return _labels;
  }

  Future refreshLabels() async {
    _labels = await _db.getLabels(query: {'orderBy': 'position'});
    // debugPrint('labels: $labels');
    notifyListeners();
  }

  Future<List<StationLabel>> getLabels({Map<String, dynamic>? query}) async {
    return _db.getLabels(query: query);
  }

  Future addLabel(StationLabel label) async {
    await _db.addLabel(label);
    refreshLabels();
  }

  Future updateLabel(StationLabel label) async {
    await _db.updateLabel(label);
    refreshLabels();
  }

  Future deleteLabel(StationLabel label) async {
    // get stations having the label
    final stations = await _db.getStations(query: {
      'where': 'labels LIKE ?',
      'whereArgs': ['%${label.name}%'],
    });
    for (final station in stations) {
      // remove the label
      station.labels.remove(label.name);
      // update the station info
      await _db.updateStation(station);
    }
    // delete the label from the database
    await _db.deleteLabel(label);
    // refresh label
    refreshLabels();
    // change the current label to default
    setCurrentLabel(StationLabel.getDefault());
  }

  Future restoreCurrentLabel() async {
    final prefs = await SharedPreferences.getInstance();
    final dataStr = prefs.getString('label');
    _currentLabel = dataStr != null
        ? StationLabel.fromPrefString(dataStr)
        : StationLabel.getDefault();
  }

  Future backupCurrentLabel() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentLabel != null) {
      final dataStr = _currentLabel!.toPrefString();
      await prefs.setString('label', dataStr);
    }
  }

  Future setCurrentLabel(StationLabel label) async {
    _currentLabel = label;
    await backupCurrentLabel();
    refreshStations();
  }

  StationLabel getCurrentLabel() {
    return _currentLabel ?? StationLabel.getDefault();
  }
}
