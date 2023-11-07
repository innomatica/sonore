import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'logic/station.dart';
import 'screens/home/home.dart';
import 'screens/mapview/mapview.dart';
import 'services/apptheme.dart';
import 'services/audiohandler.dart';

void main() async {
  // it should be the first line in main method
  WidgetsFlutterBinding.ensureInitialized();

  final handler = await createAudioHandler();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider<StationBloc>(create: (_) => StationBloc()),
      Provider<SonoreAudioHandler>(
        create: (context) {
          handler.setLogic(context.read<StationBloc>());
          return handler;
        },
      ),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
        builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
      return MaterialApp(
          title: 'Sonore',
          theme: AppTheme.lightTheme(lightDynamic),
          darkTheme: AppTheme.darkTheme(darkDynamic),
          // home: const HomePage(),
          debugShowCheckedModeBanner: false,
          onGenerateRoute: (settings) {
            if (settings.name != null) {
              // root
              if (settings.name == '/') {
                return MaterialPageRoute(
                    builder: (context) => const HomePage());
              }
            }
            return MaterialPageRoute(builder: (context) => const UnknownPage());
          },
          initialRoute: '/',
          routes: {
            '/': (context) => const HomePage(),
            '/map': (context) => const RadioBrowserMap(),
          });
    });
  }
}

class UnknownPage extends StatelessWidget {
  const UnknownPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Center(child: Text('link is not valid')),
    );
  }
}
