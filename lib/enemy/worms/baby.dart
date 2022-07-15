import 'dart:math';

import 'package:contra/bullets/bullet.dart';
import 'package:contra/player/player.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../../events/event.dart';

class BabyWorm extends SpriteAnimationComponent
    with HasGameRef, CollisionCallbacks {
  final Vector2 textureSize = Vector2(26, 26);
  PlayerInfoArgs? playerInfoArgs;

  BabyWorm({required super.position}) {
    size = textureSize;
    add(CircleHitbox(radius: 13));
  }

  @override
  Future<void>? onLoad() async {
    playerInfoEvents.subscribe((args) {
      playerInfoArgs = args;
    });
    animation = await gameRef.loadSpriteAnimation(
        'baby_worm.png',
        SpriteAnimationData.sequenced(
            amount: 2, stepTime: 0.2, textureSize: textureSize));
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (playerInfoArgs != null) {
      final target = playerInfoArgs!.position + Vector2(41, 42) / 2;
      final angle = atan2(target.y - y, target.x - x);
      var velocity = Vector2(cos(angle), sin(angle)).normalized();
      position.add(velocity * 50 * dt);
    }
    super.update(dt);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Lance) {
      other.die();
    }
    if (other is Bullet) {
      removeFromParent();
      other.removeFromParent();
    }
    super.onCollision(intersectionPoints, other);
  }
}
