import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';

import 'logic/station.dart';
import 'screens/home/home.dart';
import 'services/apptheme.dart';
import 'services/radio_player.dart';

void main() async {
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
    // check https://github.com/ryanheise/just_audio/issues/619
    androidNotificationIcon: 'drawable/app_icon',
  );

  //
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<RadioPlayer>(
          create: (_) => RadioPlayer(),
        ),
        ChangeNotifierProvider<StationBloc>(
          create: (_) => StationBloc(),
        ),
      ],
      child: DynamicColorBuilder(
          builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp(
          title: 'Sonore',
          theme: AppTheme.lightTheme(lightDynamic),
          darkTheme: AppTheme.darkTheme(darkDynamic),
          home: const HomePage(),
          debugShowCheckedModeBanner: false,
          onGenerateRoute: (settings) {
            if (settings.name != null) {
              // root
              if (settings.name == '/') {
                return MaterialPageRoute(
                    builder: (context) => const HomePage());
              }
              // Deeplink was a kind of broken after Android 10.
              // Not fully fixed as of 2022.

              // final uri = Uri.parse(settings.name!);
              // debugPrint('path: ${uri.path}');
              // debugPrint('params: ${uri.queryParameters}');
              // if (uri.path == '/newstation' &&
              //     uri.queryParameters.containsKey('uuid')) {
              //   return MaterialPageRoute(
              //     builder: (context) =>
              //         StationDetails(uuid: uri.queryParameters['uuid']!),
              //   );
              // }
            }
            return MaterialPageRoute(builder: (context) => const UnknownPage());
          },
        );
      }),
    );
  }
}

class UnknownPage extends StatelessWidget {
  const UnknownPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Center(child: Text('link is not valid')),
    );
  }
}
