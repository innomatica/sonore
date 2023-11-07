import 'package:flutter/material.dart';

import 'app_info.dart';
import 'attribution.dart';
import 'disclaimer.dart';
import 'privacy.dart';

class About extends StatefulWidget {
  const About({super.key});

  @override
  State<About> createState() => _AboutState();
}

class _AboutState extends State<About> {
  final List<bool> _expandedFlag = [
    false,
    false,
    false,
    false,
    false,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: const Text('About'),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 10.0,
            horizontal: 10.0,
          ),
          child: ExpansionPanelList(
            expansionCallback: (int index, bool isExpanded) {
              setState(() {
                _expandedFlag[index] = !isExpanded;
              });
            },
            children: [
              // app info
              ExpansionPanel(
                headerBuilder: (context, isExpanded) {
                  return const ListTile(title: Text('App Information'));
                },
                body: const AppInfo(),
                isExpanded: _expandedFlag[0],
                canTapOnHeader: true,
              ),
              // attribution
              ExpansionPanel(
                headerBuilder: (context, isExpanded) {
                  return const ListTile(title: Text('Attributions'));
                },
                body: const Attribution(),
                isExpanded: _expandedFlag[1],
                canTapOnHeader: true,
              ),
              // disclaimer
              ExpansionPanel(
                headerBuilder: (context, isExpanded) {
                  return const ListTile(title: Text('Disclaimer'));
                },
                body: const Disclaimer(),
                isExpanded: _expandedFlag[2],
                canTapOnHeader: true,
              ),
              // policy
              ExpansionPanel(
                headerBuilder: (context, isExpanded) {
                  return const ListTile(title: Text('Privacy Policy'));
                },
                body: const Privacy(),
                isExpanded: _expandedFlag[3],
                canTapOnHeader: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
