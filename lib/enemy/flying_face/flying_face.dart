import 'dart:async';

import 'package:contra/enemy/flying_face/flying_face_bullet.dart';
import 'package:flame/components.dart' hide Timer;
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

class FlyingFace extends SpriteAnimationComponent with HasGameRef {
  Vector2 destination;
  late Timer timer;

  FlyingFace({
    required super.position,
    required this.destination,
  }) {
    size = Vector2(34, 32);
    positionType = PositionType.viewport;
    anchor = Anchor.center;
  }

  @override
  Future<void>? onLoad() async {
    add(SequenceEffect([
      MoveToEffect(
          destination,
          EffectController(
              duration: 2, reverseDuration: 2, curve: Curves.easeInCubic)),
      OpacityEffect.by(
          1,
          EffectController(
            duration: 1,
            curve: Curves.bounceInOut,
            reverseDuration: 1,
          ))
    ], infinite: true));
    timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      gameRef.add(FlyingFaceBullet(
        position: gameRef.camera.unprojectVector(position) + Vector2(0, 20),
      ));
    });
    animation = await gameRef.loadSpriteAnimation(
        'flying_face.png',
        SpriteAnimationData.sequenced(
            amount: 3, stepTime: 0.15, textureSize: Vector2(34, 32)));
    return super.onLoad();
  }

  @override
  void onRemove() {
    super.onRemove();
    timer.cancel();
  }
}
