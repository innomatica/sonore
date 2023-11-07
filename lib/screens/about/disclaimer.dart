import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../shared/settings.dart';

class Disclaimer extends StatelessWidget {
  const Disclaimer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      children: [
        ListTile(
          title: Text(
            'No Responsibility',
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
          subtitle: const Text(
              'Any media content provided by this app is supplied by each '
              'radio stations in the internet. We will not be liable to anyone '
              'for the content itself (tap me for the full text).'),
          onTap: () {
            launchUrl(Uri.parse(urlDisclaimer));
          },
        ),
        const SizedBox(height: 12, width: 0),
      ],
    );
  }
}
