import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'sqlite.dart';
import '../models/station.dart';
import '../shared/constants.dart';

import '../shared/settings.dart';

class StationApiService {
  static final _db = SqliteService();

  static Future<List<Station>> getTopStations(
      {int count = 100, String type = 'topvote'}) async {
    // return value
    final stations = <Station>[];
    final serverIpv4 = await _getRandomizedServerIp();
    final url = Uri(
        scheme: 'http',
        host: serverIpv4,
        path: '/json/stations/$type/${count.toString()}',
        queryParameters: {'hidebroken': 'true'});
    // debugPrint('url:$url');

    final res = await http.get(url, headers: {'User-Agent': appId});
    if (res.statusCode == 200) {
      // list of current stations
      final current = await _db.getStations();
      try {
        for (final item
            in jsonDecode(utf8.decode(res.bodyBytes, allowMalformed: true))) {
          final station = Station.fromRadioBrowserApi(item);
          // check if you already have the station registered
          if (current.any((e) => e.uuid == station.uuid)) {
            // mark the station
            station.state = 'registered';
          }
          stations.add(station);
          // debugPrint('item: $item');
          // debugPrint('station: $station');
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    return stations;
  }

  static Future<List<Station>> searchStations(
      Map<String, dynamic>? params) async {
    final serverIpv4 = await _getRandomizedServerIp();
    final url = Uri(
      scheme: 'http',
      host: serverIpv4,
      path: '/json/stations/search',
      queryParameters: params ?? {'limit': '100'},
    );
    debugPrint('url:$url');
    final res = await http.get(url, headers: {'User-Agent': appId});
    // list of current stations
    final current = await _db.getStations();
    // return value
    final stations = <Station>[];
    try {
      for (final item
          in jsonDecode(utf8.decode(res.bodyBytes, allowMalformed: true))) {
        final station = Station.fromRadioBrowserApi(item);
        // check if you already have the station registered
        if (current.any((e) => e.uuid == station.uuid)) {
          // mark the station
          station.state = 'registered';
        }
        stations.add(station);
        // debugPrint('item: $item');
        // debugPrint('station: $station');
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    return stations;
  }

  //
  // Search Station by UUIDs
  //
  static Future<List<Station>> getStationByIds(List<String> uuids) async {
    debugPrint('getStationByIds: $uuids');
    final serverIpv4 = await _getRandomizedServerIp();
    final url = Uri(
      scheme: 'http',
      host: serverIpv4,
      path: '/json/stations/byuuid',
      queryParameters: {'uuids': uuids.join(',')},
    );
    // return value
    final stations = <Station>[];
    // debugPrint('url:$url');
    final res = await http.get(url, headers: {'User-Agent': appId});
    // final current = await _db.getStations();
    try {
      for (final item
          in jsonDecode(utf8.decode(res.bodyBytes, allowMalformed: true))) {
        stations.add(Station.fromRadioBrowserApi(item));
      }
      // debugPrint('station: $stations');
    } catch (e) {
      debugPrint(e.toString());
    }
    return stations;
  }

  static Future<String> _getRandomizedServerIp() async {
    final addrs = await InternetAddress.lookup(urlServersRadioBrowser);
    // get IPv4 servers
    final servers =
        addrs.where((element) => element.type == InternetAddressType.IPv4);
    // choose one randomly
    final chosen = servers.elementAt(Random().nextInt(servers.length));
    // debugPrint('server: $chosen');
    return chosen.address;
  }

  static Future voteForStation(Station station) async {
    final serverIpv4 = await _getRandomizedServerIp();
    final url = Uri(
      scheme: 'http',
      host: serverIpv4,
      path: '/json/vote/${station.uuid}',
    );
    // debugPrint('url:$url');
    final res = await http.get(url, headers: {'User-Agent': appId});
    debugPrint('voteForStation: ${res.body}');
    final ret = jsonDecode(res.body) as Map<String, dynamic>;
    if (ret['ok']) {
      // debugPrint('voted successfully');
      station.userData['voted'] = true;
      station.votes = station.votes + 1;
      _db.updateStation(station);
    }
  }

  static Future reportClick(Station station) async {
    final serverIpv4 = await _getRandomizedServerIp();
    final url = Uri(
      scheme: 'http',
      host: serverIpv4,
      path: '/json/url/${station.uuid}',
    );
    // debugPrint('url:$url');
    final res = await http.get(url, headers: {'User-Agent': appId});
    debugPrint('reportClick: ${res.body}');
    final ret = jsonDecode(res.body) as Map<String, dynamic>;
    if (ret['ok']) {
      // debugPrint('click report sucess');
      station.info['clickCount'] = station.info['clickCount'] + 1;
      _db.updateStation(station);
    }
  }

  static Future<List<Station>> getFavoriteStations() async {
    // return value
    final stations = <Station>[];
    // get favorite data
    final res = await http.get(Uri.parse(urlStationsJson));
    if (res.statusCode == 200) {
      // decode data part of the res
      final data = jsonDecode(res.body)['data'];
      // debugPrint('data: $data');
      // validate data
      if (data is List && data.isNotEmpty == true) {
        // get stations by UUID list from the data above
        final results = await getStationByIds(
            data.map((u) => u["uuid"] as String).toList());
        // fetch existing stations for the comparison
        final current = await _db.getStations();
        for (final result in results) {
          // mark registered if the station is not new
          if (current.any((e) => e.uuid == result.uuid)) {
            result.state = 'registered';
          }
          stations.add(result);
        }
      }
    }
    return stations;
  }
}
