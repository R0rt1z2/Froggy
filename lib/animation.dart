import 'package:flutter/material.dart';
import 'package:flare_flutter/flare_actor.dart';

class FilePair {
  String backgroundFile;
  String animationFile;
  FilePair(this.backgroundFile, this.animationFile);
}

class FroggyAnimation {
  String backgroundFile;
  String animationFile;
  String currentAnimation = '';

  List<String> animationNames = [
    'Hero-Action', 'Sub-Action 01', 'Sub-Action 02'
  ];

  FroggyAnimation({required this.backgroundFile, required this.animationFile}) {
    currentAnimation = animationNames[0];
  }

  Widget getAnimation() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: FlareActor(
        'assets/$animationFile',
        alignment: Alignment.center,
        fit: BoxFit.cover,
        animation: currentAnimation,
        isPaused: false,
      ),
    );
  }

  Widget getBackground() {
    return Image.asset(
      'assets/$backgroundFile',
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
    );
  }

  void changeAnimation() {
    int index = animationNames.indexOf(currentAnimation);
    index = (index + 1) % animationNames.length;
    currentAnimation = animationNames[index];
  }
}