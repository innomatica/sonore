import 'dart:convert';

import 'package:sonoreapp/shared/settings.dart';

class StationLabel {
  int? id;
  int position;
  String name;
  Map<String, dynamic>? info;

  StationLabel({
    this.id,
    required this.position,
    required this.name,
    this.info,
  });

  factory StationLabel.fromDatabaseMap(Map<String, dynamic> item) {
    return StationLabel(
      id: item['id'],
      position: item['position'],
      name: item['name'],
      info: item['info'] != null ? jsonDecode(item['info']) : null,
    );
  }

  factory StationLabel.fromPrefString(String dataStr) {
    final data = jsonDecode(dataStr);
    return StationLabel(
      id: data['id'],
      position: data['position'],
      name: data['name'],
      info: data['info'],
    );
  }

  factory StationLabel.getDefault() {
    return StationLabel(position: -1, name: allStations, info: {});
  }

  Map<String, dynamic> toDatabaseMap() {
    return {
      'id': id,
      'position': position,
      'name': name,
      'info': jsonEncode(info),
    };
  }

  String toPrefString() {
    return jsonEncode({
      'id': id,
      'position': position,
      'name': name,
      'info': info,
    });
  }

  @override
  String toString() {
    return toDatabaseMap().toString();
  }
}
