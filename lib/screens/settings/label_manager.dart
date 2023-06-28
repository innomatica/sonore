import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../../logic/station.dart';
import '../../models/label.dart';

class LabelManager extends StatefulWidget {
  const LabelManager({Key? key}) : super(key: key);

  @override
  State<LabelManager> createState() => _LabelManagerState();
}

class _LabelManagerState extends State<LabelManager> {
  // final _db = SqliteService();
  String? _newLabelName;
  int _itemCount = 0;
  bool _isFabVisible = true;

  Widget _buildBottomSheet(context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
          left: 12,
          right: 12),
      child: TextFormField(
        decoration: InputDecoration(
          label: const Text('Label Name'),
          hintText: 'Daily Dose of Acid Jazz',
          suffix: IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.of(context).pop(_newLabelName);
            },
          ),
        ),
        onChanged: (value) {
          _newLabelName = value;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.watch<StationBloc>();
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color oddItemColor = colorScheme.primary.withOpacity(0.05);
    final Color evenItemColor = colorScheme.primary.withOpacity(0.15);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Labels'),
      ),
      body: FutureBuilder<List<StationLabel>>(
          future: bloc.getLabels(query: {'orderBy': 'position'}),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final labels = snapshot.data!;
              _itemCount = labels.length;
              return NotificationListener<UserScrollNotification>(
                onNotification: (notification) {
                  if (notification.direction == ScrollDirection.forward) {
                    if (!_isFabVisible) setState(() => _isFabVisible = true);
                  } else if (notification.direction ==
                      ScrollDirection.reverse) {
                    if (_isFabVisible) setState(() => _isFabVisible = false);
                  }
                  return false;
                },
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: labels.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      key: Key('$index'),
                      tileColor: index % 2 == 0 ? evenItemColor : oddItemColor,
                      leading: const Icon(Icons.drag_indicator_rounded),
                      title: Text(labels[index].name),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.delete_rounded,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        onPressed: () {
                          bloc.deleteLabel(labels[index]);
                          setState(() {});
                        },
                      ),
                    );
                  },
                  onReorder: (int oldIndex, int newIndex) async {
                    debugPrint('oldIndex: $oldIndex, newIndex:$newIndex');
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    final label = labels.removeAt(oldIndex);
                    labels.insert(newIndex, label);
                    for (int idx = 0; idx < labels.length; idx += 1) {
                      labels[idx].position = idx;
                      await bloc.updateLabel(labels[idx]);
                    }
                    setState(() {});
                  },
                ),
              );
            } else {
              return Container();
            }
          }),
      // resizeToAvoidBottomInset: true,
      floatingActionButton: _isFabVisible
          ? FloatingActionButton(
              child: const Icon(Icons.add_rounded),
              onPressed: () {
                showModalBottomSheet(
                  isScrollControlled: true,
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(8.0)),
                  ),
                  builder: _buildBottomSheet,
                ).then((value) {
                  if (value != null && value.isNotEmpty) {
                    bloc.addLabel(
                        StationLabel(position: _itemCount, name: value));
                    debugPrint('new label added');
                    setState(() {});
                  }
                });
              },
            )
          : Container(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
