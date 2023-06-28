// import 'dart:io' show Platform;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:sonoreapp/shared/settings.dart';

import '../../logic/station.dart';
import '../../models/station.dart';
import '../../services/station_api.dart';
import '../../shared/helpers.dart';

class StationSearch extends StatefulWidget {
  const StationSearch({Key? key}) : super(key: key);

  @override
  State<StationSearch> createState() => _StationSearchState();
}

class _StationSearchState extends State<StationSearch> {
  final _formKey = GlobalKey<FormState>();
  final _typeAheadController = TextEditingController();
  // String? _countryCode = Platform.localeName.split('_')[1];
  String? _countryCode;

  String? _keyword;
  String? _uuid;
  String? _minBitrate;
  bool _byStationName = false;
  bool _showKeywordSearch = false;
  bool _showUuidSearch = false;

  //
  // Search Result Dialog
  //
  StatefulBuilder _buildStationSelection(
      {required String title, required List<Station> stations}) {
    final bloc = context.read<StationBloc>();
    return StatefulBuilder(builder: (context, setState) {
      return AlertDialog(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: stations.length,
            itemBuilder: (context, index) {
              final station = stations[index];
              return CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: station.state == 'selected',
                onChanged: station.state == 'registered'
                    // no action will be done if it is already registered
                    ? null
                    : (value) {
                        if (value != null) {
                          value
                              ? station.state = 'selected'
                              : station.state = 'unselected';
                          setState(() {});
                        }
                      },
                title: Text(
                  station.name,
                  style: const TextStyle(fontSize: 15.0),
                ),
                subtitle: Text(station.info['language']),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Close'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            child: const Text('Add Selected'),
            onPressed: () {
              for (final station in stations) {
                if (station.state != null && station.state == 'selected') {
                  bloc.addStation(station);
                }
              }
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('station(s) added')));
            },
          ),
        ],
      );
    });
  }

  //
  // Keyword Search
  //
  Widget _buildKeywordSearch() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TypeAheadFormField(
            textFieldConfiguration: TextFieldConfiguration(
              controller: _typeAheadController,
              decoration: const InputDecoration(
                labelText: 'Keyword',
                hintText: 'rock, classic, ottawa, ...',
              ),
            ),
            suggestionsCallback: (pattern) {
              return StationTag.getSuggestions(pattern);
            },
            itemBuilder: (BuildContext context, String suggestion) {
              return ListTile(
                title: Text(suggestion),
              );
            },
            transitionBuilder: (context, suggestionsBox, controller) {
              return suggestionsBox;
            },
            onSuggestionSelected: (String suggestion) {
              debugPrint('suggestion selected: $suggestion');
              _typeAheadController.text = suggestion;
            },
            noItemsFoundBuilder: (value) {
              return const SizedBox(width: 0, height: 0);
            },
            validator: (String? value) {
              if (value != null && value.isEmpty) {
                return 'Please enter a keyword';
              }
              return null;
            },
            onSaved: (String? value) {
              debugPrint('onSaved: $value');
              _keyword = value;
            },
          ),
          SwitchListTile(
            title: const Text('by Station Name'),
            value: _byStationName,
            onChanged: (value) {
              setState(() {
                _byStationName = value;
              });
            },
          ),
          // SwitchListTile(
          //   title: Text('Only in ${CountryName.getName(_countryCode)}'),
          //   value: _byCountry,
          //   onChanged: (value) {
          //     setState(() {
          //       _byCountry = value;
          //     });
          //   },
          // ),
          ListTile(
            title: const Text('Only Stations in'),
            trailing: DropdownButton<String>(
              value: _countryCode,
              icon: const Icon(Icons.arrow_downward),
              onChanged: (value) {
                setState(() {
                  _countryCode = value;
                  // _byCountry = CountryName.getName(_countryCode);
                });
              },
              items: CountryName.codes
                  .map<DropdownMenuItem<String>>(
                      (String value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ))
                  .toList(),
            ),
          ),
          ListTile(
            title: const Text('Min Bitrate (kbps)'),
            trailing: DropdownButton<String>(
              value: _minBitrate,
              icon: const Icon(Icons.arrow_downward),
              onChanged: (value) {
                setState(() {
                  _minBitrate = value;
                });
              },
              items: <String>['32', '56', '64', '128', '192', '256', '320']
                  .map<DropdownMenuItem<String>>(
                      (String value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ))
                  .toList(),
            ),
          ),
          ElevatedButton(
            child: const Text('search'),
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();

                debugPrint('keyword: $_keyword');
                debugPrint('controller: ${_typeAheadController.text}');
                if (_keyword == null || _keyword!.isEmpty) {
                  _keyword = _typeAheadController.text;
                }
                // build search parameters
                final params = <String, dynamic>{};
                // station name
                if (_byStationName) {
                  params['name'] = _keyword;
                } else {
                  if (_keyword!.contains(',')) {
                    params['tagList'] = _keyword;
                  } else {
                    params['tag'] = _keyword;
                  }
                }
                // country code
                if (_countryCode != null) {
                  params['countrycode'] = _countryCode;
                }
                // minimum bitrate
                if (_minBitrate != null) {
                  params['bitrateMin'] = _minBitrate;
                }
                // default paramters
                params['limit'] = '100';
                params['hidebroken'] = 'true';

                final stations = await StationApiService.searchStations(params);
                setState(() {
                  _showKeywordSearch = false;
                  _showUuidSearch = false;
                });
                if (!mounted) return;
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) {
                    return _buildStationSelection(
                      title: 'Stations by Keyword (${stations.length})',
                      stations: stations,
                    );
                  },
                );
              }
            },
          ),
        ],
      ),
    );
  }

  //
  // UUID Search
  //
  Widget _buildUuidSearch() {
    return Column(
      children: [
        TextField(
          onChanged: ((value) => _uuid = value),
        ),
        const SizedBox(height: 8.0),
        ElevatedButton(
          child: const Text('search'),
          onPressed: () async {
            if (_uuid != null && _uuid!.isNotEmpty) {
              final stations =
                  await StationApiService.getStationByIds([_uuid!]);
              setState(() {
                _showKeywordSearch = false;
                _showUuidSearch = false;
              });
              if (!mounted) return;
              if (stations.isNotEmpty) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) {
                    return _buildStationSelection(
                      title: 'Station by UUID',
                      stations: stations,
                    );
                  },
                );
              } else {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Cannot find the station'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Check the UUID'),
                          Text(
                            _uuid!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: (() => Navigator.of(context).pop()),
                          child: const Text('close'),
                        ),
                      ],
                    );
                  },
                );
              }
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Stations'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            //
            // Search By Keyword
            //
            ListTile(
              leading: Icon(
                Icons.search_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Search by Keyword'),
              onTap: () {
                if (_showKeywordSearch) {
                  _showKeywordSearch = false;
                } else {
                  _showKeywordSearch = true;
                  _showUuidSearch = false;
                }
                _typeAheadController.clear();
                _byStationName = false;
                _countryCode = null;
                _minBitrate = null;
                setState(() {});
              },
              subtitle: _showKeywordSearch ? _buildKeywordSearch() : null,
            ),
            //
            // Search by UUID
            //
            ListTile(
              leading: Icon(
                Icons.fact_check_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Search by Station UUID'),
              onTap: () {
                if (_showUuidSearch) {
                  _showUuidSearch = false;
                } else {
                  _showUuidSearch = true;
                  _showKeywordSearch = false;
                }
                setState(() {});
              },
              subtitle: _showUuidSearch ? _buildUuidSearch() : null,
            ),
            //
            // Top 100 Stations by Clicks
            //
            ListTile(
              leading: Icon(
                Icons.ads_click_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Top 100 Stations by Clicks'),
              onTap: () async {
                _showKeywordSearch = false;
                _showUuidSearch = false;
                setState(() {});
                final stations = await StationApiService.getTopStations(
                    count: 100, type: 'topclick');
                if (!mounted) return;
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) {
                    return _buildStationSelection(
                      title: 'Top 100 Stations by Clicks',
                      stations: stations,
                    );
                  },
                );
              },
            ),
            //
            // Top 100 Stations by Votes
            //
            ListTile(
              leading: Icon(
                Icons.thumb_up_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Top 100 Stations by Votes'),
              onTap: () async {
                _showKeywordSearch = false;
                _showUuidSearch = false;
                setState(() {});
                final stations = await StationApiService.getTopStations(
                    count: 100, type: 'topvote');
                if (!mounted) return;
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) {
                    return _buildStationSelection(
                      title: 'Top 100 Stations by Votes',
                      stations: stations,
                    );
                  },
                );
              },
            ),
            //
            // Sonore Favorites
            //
            ListTile(
              leading: Icon(
                Icons.favorite_border_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Sonore Favorites'),
              onTap: () async {
                _showKeywordSearch = false;
                _showUuidSearch = false;
                setState(() {});
                final uuids = <String>[];
                final res = await http.get(Uri.parse(urlStationsJson));
                if (res.statusCode == 200) {
                  for (final item in jsonDecode(res.body)['data']) {
                    uuids.add(item['uuid']);
                  }
                  debugPrint('$uuids');
                  // get stations by uuids
                  if (uuids.isNotEmpty) {
                    final stations =
                        await StationApiService.getStationByIds(uuids);
                    if (!mounted) return;
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) {
                        return _buildStationSelection(
                          title: 'Sonore Favorites',
                          stations: stations,
                        );
                      },
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('failed to connect to the server')));
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
