import 'package:flutter/material.dart';

//
// Instruction: Start
//
class FirstTime extends StatelessWidget {
  const FirstTime({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Welcome to Sonore',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.tertiary,
              )),
          const SizedBox(height: 16.0, width: 0.0),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Go to', style: textStyle),
              const Icon(Icons.more_vert_rounded),
              const Text('and add new stations ', style: textStyle),
              Icon(Icons.cell_tower_rounded,
                  color: Theme.of(context).colorScheme.primary),
            ],
          ),
          const SizedBox(height: 8.0, width: 0.0),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('You can search ', style: textStyle),
              Icon(
                Icons.search_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const Text(' your favorite ones', style: textStyle),
            ],
          ),
          const SizedBox(height: 8.0, width: 0.0),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Or, you can try what others like ', style: textStyle),
              Icon(
                Icons.thumb_up_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

//
// Instruction: No Stations for the label
//
class EmptyList extends StatelessWidget {
  const EmptyList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('No station under this label',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              )),
          const SizedBox(height: 16.0, width: 0.0),
          const Text('Tap on the station card', style: textStyle),
          const SizedBox(height: 8.0, width: 0.0),
          const Text('and choose label(s) for the station', style: textStyle),
        ],
      ),
    );
  }
}
