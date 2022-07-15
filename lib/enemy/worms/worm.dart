import 'dart:async';

import 'package:contra/enemy/worms/baby.dart';
import 'package:flame/components.dart' hide Timer;

class Worm extends SpriteAnimationComponent with HasGameRef {
  Worm({required super.position});

  @override
  Future<void>? onLoad() async {
    size = Vector2(105, 112);
    animation = await gameRef.loadSpriteAnimation(
        'worms.png',
        SpriteAnimationData.sequenced(
            amount: 2, stepTime: 0.4, textureSize: Vector2(105, 112)));
    Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      gameRef.add(BabyWorm(position: position + Vector2(80, 90)));
    });
    return super.onLoad();
  }
}
