import 'dart:convert';

class Station {
  String uuid;
  String name;
  String url;
  String image;
  int bitrate;
  int votes;
  DateTime lastChanged;
  Map<String, dynamic> info;
  // int categoryId;
  Map<String, dynamic> userData;
  List<String> labels;
  String? state; // used during station search

  Station({
    required this.uuid,
    required this.name,
    required this.url,
    required this.image,
    required this.bitrate,
    required this.votes,
    required this.lastChanged,
    required this.info,
    // required this.categoryId,
    required this.userData,
    required this.labels,
  });

  factory Station.fromDatabaseMap(Map<String, dynamic> item) {
    // debugPrint('Station.fromDatabaseMap: $item');
    return Station(
      uuid: item['uuid'],
      name: item['name'],
      url: item['url'],
      image: item['image'],
      bitrate: item['bitrate'],
      votes: item['votes'],
      lastChanged: DateTime.tryParse(item['lastChanged']) ?? DateTime.now(),
      info: jsonDecode(item['info']) ?? {},
      // categoryId: item['categoryId'],
      labels:
          item['labels']?.isNotEmpty ? item['labels'].split(',') : <String>[],
      userData: jsonDecode(item['userData']),
    );
  }

  factory Station.fromRadioBrowserApi(Map<String, dynamic> item) {
    return Station(
      uuid: item['stationuuid'],
      name: item['name'].trim(),
      url: item['url_resolved'],
      image: item['favicon'],
      bitrate: item['bitrate'],
      votes: item['votes'],
      lastChanged: DateTime.parse(item['lastchangetime_iso8601']),
      info: {
        'changeUuid': item['changeuuid'],
        'url': item['url'],
        'homepage': item['homepage'],
        'tags': item['tags'].replaceAll(',', ', '),
        'country': item['country'],
        'countryCode': item['countrycode'],
        'state': item['state'],
        'language': item['language'],
        'languageCodes': item['languagecodes'],
        'codec': item['codec'],
        'hls': item['hls'],
        'lastCheckOk': item['lastcheckok'],
        'lastChecked': item['lastchangetime_iso8601'],
        'lastClicked': item['lastclicktimestamp_iso8601'],
        'clickCount': item['clickcount'],
        'clickTrend': item['clickTrend'],
        'sslError': item['ssl_error'],
        'geoLat': item['geo_lat'],
        'geoLng': item['geo_long'],
        'hasExtendedInfo': item['has_extended_info'],
      },
      // categoryId: defaultCategoryId,
      userData: {},
      labels: <String>[],
    );
  }

  factory Station.fromYaml(Map<String, dynamic> item) {
    return Station(
      uuid: item['stationuuid'],
      name: item['name'].trim(),
      url: item['url_resolved'],
      image: item['favicon'],
      bitrate: item['bitrate'],
      votes: item['votes'],
      lastChanged: DateTime.parse(item['lastchangetime_iso8601']),
      info: {
        'changeUuid': item['changeuuid'],
        'url': item['url'],
        'homepage': item['homepage'],
        'tags': item['tags'].replaceAll(',', ', '),
        'country': item['country'],
        'countryCode': item['countrycode'],
        'state': item['state'],
        'language': item['language'],
        'languageCodes': item['languagecodes'],
        'codec': item['codec'],
        'hls': item['hls'],
        'lastCheckOk': item['lastcheckok'],
        'lastChecked': item['lastchangetime_iso8601'],
        'lastClicked': item['lastclicktimestamp_iso8601'],
        'clickCount': item['clickcount'],
        'clickTrend': item['clickTrend'],
        'sslError': item['ssl_error'],
        'geoLat': item['geo_lat'],
        'geoLng': item['geo_long'],
        'hasExtendedInfo': item['has_extended_info'],
      },
      // categoryId: defaultCategoryId,
      userData: {},
      labels: <String>[],
    );
  }

  Map<String, dynamic> toDatabaseMap() {
    return {
      'uuid': uuid,
      'name': name,
      'url': url,
      'image': image,
      'bitrate': bitrate,
      'votes': votes,
      'lastChanged': lastChanged.toIso8601String(),
      'info': jsonEncode(info),
      // 'categoryId': categoryId,
      'userData': jsonEncode(userData),
      'labels': labels.join(","),
    };
  }

  @override
  String toString() {
    return toDatabaseMap().toString();
  }
}
