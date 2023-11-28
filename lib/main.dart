import 'package:flutter/material.dart';
import 'package:flare_flutter/flare_actor.dart';

import 'animation.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google\'s Weather Frog (Froggy)',
      home: AnimationScreen(),
    );
  }
}

class AnimationScreen extends StatefulWidget {
  @override
  _AnimationScreenState createState() => _AnimationScreenState();
}

class _AnimationScreenState extends State<AnimationScreen> {
  List<FilePair> filePairs = [
    FilePair('fields_day_cloudy_bg.webp', 'fields_day_cloudy_frog.flr'),
    FilePair('fields_day_hazy_bg.webp', 'fields_day_hazy_frog.flr'),
    FilePair('fields_day_rainy_bg.webp', 'fields_day_rainy_frog.flr'),
    FilePair('fields_day_snowy_bg.webp', 'fields_day_snowy_frog.flr'),
    FilePair('fields_day_sunny_bg.webp', 'fields_day_sunny_frog.flr'),
    FilePair('fields_morning_cloudy_bg.webp', 'fields_morning_cloudy_frog.flr'),
    FilePair('fields_morning_hazy_bg.webp', 'fields_morning_hazy_frog.flr'),
    FilePair('fields_day_rainy_bg.webp', 'fields_morning_rainy_frog.flr'), // Missing background
    FilePair('fields_morning_snowy_bg.webp', 'fields_morning_snowy_frog.flr'),
    FilePair('fields_morning_sunny_bg.webp', 'fields_morning_sunny_frog.flr'),
    FilePair('fields_night_hazy_bg.webp', 'fields_night_cloudy_frog.flr'), // Missing background
    FilePair('fields_night_hazy_bg.webp', 'fields_night_hazy_frog.flr'),
    // FilePair('fields_night_rainy_bg.webp', 'fields_night_rainy_frog.flr'), // Broken animation
    FilePair('fields_night_snowy_bg.webp', 'fields_night_snowy_frog.flr'),
    FilePair('fields_night_sunny_bg.webp', 'fields_night_sunny_frog.flr'),
    FilePair('fields_sunset_cloudy_bg.webp', 'fields_sunset_cloudy_frog.flr'),
    FilePair('fields_sunset_hazy_bg.webp', 'fields_sunset_hazy_frog.flr'),
    FilePair('fields_sunset_rainy_bg.webp', 'fields_sunset_rainy_frog.flr'),
    FilePair('fields_sunset_snowy_bg.webp', 'fields_sunset_snowy_frog.flr'),
    FilePair('fields_sunset_sunny_bg.webp', 'fields_sunset_sunny_frog.flr'),
    FilePair('hill_day_cloudy_bg.webp', 'hill_day_cloudy_frog.flr'),
    FilePair('hill_day_hazy_bg.webp', 'hill_day_hazy_frog.flr'),
    FilePair('hill_day_rainy_bg.webp', 'hill_day_rainy_frog.flr'),
    FilePair('hill_day_snowy_bg.webp', 'hill_day_snowy_frog.flr'),
    FilePair('hill_day_sunny_bg.webp', 'hill_day_sunny_frog.flr'),
    FilePair('hill_morning_cloudy_bg.webp', 'hill_morning_cloudy_frog.flr'),
    FilePair('hill_morning_hazy_bg.webp', 'hill_morning_hazy_frog.flr'),
    FilePair('hill_morning_rainy_bg.webp', 'hill_morning_rainy_frog.flr'),
    FilePair('hill_morning_snowy_bg.webp', 'hill_morning_snowy_frog.flr'),
    FilePair('hill_day_sunny_bg.webp', 'hill_morning_sunny_frog.flr'), // Missing background
    FilePair('hill_night_cloudy_bg.webp', 'hill_night_cloudy_frog.flr'),
    FilePair('hill_night_hazy_bg.webp', 'hill_night_hazy_frog.flr'),
    FilePair('hill_night_rainy_bg.webp', 'hill_night_rainy_frog.flr'),
    FilePair('hill_night_snowy_bg.webp', 'hill_night_snowy_frog.flr'),
    FilePair('hill_night_sunny_bg.webp', 'hill_night_sunny_frog.flr'),
    FilePair('hill_sunset_sunny_bg.webp', 'hill_sunset_sunny_frog.flr'),
    FilePair('mushroom_day_cloudy_bg.webp', 'mushroom_day_cloudy_frog.flr'),
    FilePair('mushroom_day_hazy_bg.webp', 'mushroom_day_hazy_frog.flr'),
    FilePair('mushroom_day_rainy_bg.webp', 'mushroom_day_rainy_frog.flr'),
    FilePair('mushroom_day_snowy_bg.webp', 'mushroom_day_snowy_frog.flr'),
    FilePair('mushroom_day_sunny_bg.webp', 'mushroom_day_sunny_frog.flr'),
    FilePair('mushroom_morning_cloudy_bg.webp', 'mushroom_morning_cloudy_frog.flr'),
    FilePair('mushroom_morning_hazy_bg.webp', 'mushroom_morning_hazy_frog.flr'),
    FilePair('mushroom_morning_rainy_bg.webp', 'mushroom_morning_rainy_frog.flr'),
    FilePair('mushroom_morning_snowy_bg.webp', 'mushroom_morning_snowy_frog.flr'),
    FilePair('mushroom_morning_sunny_bg.webp', 'mushroom_morning_sunny_frog.flr'),
    FilePair('mushroom_night_cloudy_bg.webp', 'mushroom_night_cloudy_frog.flr'),
    FilePair('mushroom_night_hazy_bg.webp', 'mushroom_night_hazy_frog.flr'),
    FilePair('mushroom_night_rainy_bg.webp', 'mushroom_night_rainy_frog.flr'),
    FilePair('mushroom_night_snowy_bg.webp', 'mushroom_night_snowy_frog.flr'),
    FilePair('mushroom_night_sunny_bg.webp', 'mushroom_night_sunny_frog.flr'),
    FilePair('mushroom_sunset_cloudy_bg.webp', 'mushroom_sunset_cloudy_frog.flr'),
    FilePair('mushroom_sunset_hazy_bg.webp', 'mushroom_sunset_hazy_frog.flr'),
    FilePair('mushroom_sunset_rainy_bg.webp', 'mushroom_sunset_rainy_frog.flr'),
    FilePair('mushroom_sunset_snowy_bg.webp', 'mushroom_sunset_snowy_frog.flr'),
    FilePair('mushroom_sunset_sunny_bg.webp', 'mushroom_sunset_sunny_frog.flr'),
  ];

  int currentIndex = 0;
  late List<FroggyAnimation> froggyAnimations;
  late FroggyAnimation froggyAnimation;

  @override
  void initState() {
    super.initState();
    froggyAnimations = filePairs.map((pair) {
      return FroggyAnimation(backgroundFile: pair.backgroundFile, animationFile: pair.animationFile);
    }).toList();

    froggyAnimation = froggyAnimations[currentIndex];
  }

  void _nextAnimation() {
    setState(() {
      currentIndex = (currentIndex + 1) % froggyAnimations.length;
      froggyAnimation = froggyAnimations[currentIndex];
    });
  }

  void _previousAnimation() {
    setState(() {
      currentIndex = (currentIndex - 1) % froggyAnimations.length;
      froggyAnimation = froggyAnimations[currentIndex];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          froggyAnimation.getBackground(),
          froggyAnimation.getAnimation(),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _previousAnimation,
            tooltip: 'Previous Animation',
            child: Icon(Icons.arrow_back),
          ),
          SizedBox(width: 10), // Space between buttons
          FloatingActionButton(
            onPressed: _nextAnimation,
            tooltip: 'Next Animation',
            child: Icon(Icons.arrow_forward),
          ),
        ],
      ),
    );
  }
}