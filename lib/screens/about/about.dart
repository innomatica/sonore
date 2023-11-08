import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../shared/constants.dart';
import '../../shared/settings.dart';

class About extends StatefulWidget {
  const About({super.key});

  @override
  State<About> createState() => _AboutState();
}

class _AboutState extends State<About> {
  String? _getStoreUrl() {
    if (Platform.isAndroid) {
      return urlPlayStore;
    } else if (Platform.isIOS) {
      return urlAppStore;
    }
    return urlHomePage;
  }

  Widget _buildBody() {
    final titleStyle = TextStyle(color: Theme.of(context).colorScheme.primary);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView(
        children: [
          // Version
          ListTile(
            title: Text('Version', style: titleStyle),
            subtitle: const Text(appVersion),
          ),
          // Open Source
          ListTile(
            title: Text('Open Source', style: titleStyle),
            subtitle: const Text('Visit source repository'),
            onTap: () => launchUrl(Uri.parse(urlSourceRepo)),
          ),
          // Play Store
          ListTile(
            title: Text('Play Store', style: titleStyle),
            subtitle: const Text('Review App, Report Bugs'),
            onTap: () {
              final url = _getStoreUrl();
              if (url != null) {
                launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              }
            },
          ),
          // QR Code
          ListTile(
            title: Text('Play Store QR Code', style: titleStyle),
            subtitle: const Text('Recommend to Others'),
            onTap: () {
              final url = _getStoreUrl();
              if (url != null) {
                showDialog(
                  context: context,
                  builder: (context) {
                    return SimpleDialog(
                      title: Center(
                        child: Text('Visit Our Store', style: titleStyle),
                      ),
                      backgroundColor: Colors.white,
                      children: [
                        Center(child: Image.asset(playStoreUrlQrCode))
                      ],
                    );
                  },
                );
              }
            },
          ),
          // About
          ListTile(
            title: Text('About Us', style: titleStyle),
            subtitle: const Text(urlHomePage),
            onTap: () => launchUrl(Uri.parse(urlHomePage)),
          ),
          // Radio Browser
          ListTile(
            title: Text('Radio Station Database', style: titleStyle),
            subtitle: const Text("Backend server provided by RadioBrowser"),
            onTap: () => launchUrl(Uri.parse(urlInfoRadioBroswer)),
          ),
          // App Icons
          ListTile(
            title: Text('App Icons', style: titleStyle),
            subtitle: const Text("Sound icons created by Freepik - Flaticon"),
            onTap: () => launchUrl(Uri.parse(urlAppIconSource)),
          ),
          // Store Background Image
          ListTile(
            title: Text('Store Background Image', style: titleStyle),
            subtitle: const Text("Photo by C D-X at unsplash.com"),
            onTap: () => launchUrl(Uri.parse(urlStoreImageSource)),
          ),
          // Disclaimer
          ListTile(
            title: Text('Disclaimer', style: titleStyle),
            subtitle: const Text(
                'All contents consumed using this app are supplied by each '
                'radio station in the internet, for which we will not be liable '
                'to anyone under any circumstances (tap to see the full text).'),
            onTap: () => launchUrl(Uri.parse(urlDisclaimer)),
          ),
          // Privacy Policy
          ListTile(
            title: Text('Privacy Policy', style: titleStyle),
            subtitle: const Text('We do not collect any Personal Data. '
                'We do not collect any Usage Data. '
                '(tap to see the full text).'),
            onTap: () => launchUrl(Uri.parse(urlPrivacyPolicy)),
          ),
        ],
      ),
    );
  }

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
      body: _buildBody(),
    );
  }
}
