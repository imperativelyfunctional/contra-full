import 'dart:async';
import 'dart:math';

import 'package:contra/bullets/bullet.dart';
import 'package:contra/wall/screen_hitbox.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart' hide Timer;

import '../../events/event.dart';
import '../../player/player.dart';

class FlyingFaceBullet extends SpriteAnimationComponent
    with HasGameRef, CollisionCallbacks {
  bool startTrackingPlayer = false;
  late Timer timer;
  PlayerInfoArgs? playerInfoArgs;
  Vector2? velocity;

  FlyingFaceBullet({
    required super.position,
  });

  @override
  Future<void>? onLoad() async {
    playerInfoEvents.subscribe((args) {
      playerInfoArgs = args!;
    });

    var spriteSize = Vector2(11, 8);
    anchor = Anchor.center;
    add(RectangleHitbox(size: spriteSize));
    size = spriteSize;
    animation = await gameRef.loadSpriteAnimation(
        'flying_face_b.png',
        SpriteAnimationData.sequenced(
            amount: 2, stepTime: 0.4, textureSize: spriteSize));
    timer = Timer(const Duration(seconds: 2), () {
      startTrackingPlayer = true;
    });
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (startTrackingPlayer && playerInfoArgs != null) {
      final target = playerInfoArgs!.position + Vector2(41, 42) / 2;
      final angle = atan2(target.y - y, target.x - x);
      velocity ??= Vector2(cos(angle), sin(angle)).normalized();
      if (velocity != null) {
        position.add(velocity! * 100 * dt);
      }
    }
    super.update(dt);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is ContraScreenHitbox || other is Bullet || other is Lance) {
      timer.cancel();
      removeFromParent();
      if (other is Lance) {
        other.die();
      }
    }
    super.onCollision(intersectionPoints, other);
  }
}
