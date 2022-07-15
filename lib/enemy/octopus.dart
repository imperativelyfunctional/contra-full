import 'package:contra/bullets/bullet.dart';
import 'package:contra/player/player.dart';
import 'package:contra/wall/screen_hitbox.dart';
import 'package:contra/wall/wall.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../events/event.dart';

enum OctopusStates {
  motionless,
  running,
}

class Octopus extends SpriteAnimationGroupComponent
    with HasGameRef, CollisionCallbacks {
  final Vector2 textureSize = Vector2(30, 32);
  double speedY = 30;
  double speedX = 0;
  PlayerInfoArgs? playerInfoArgs;
  bool collided = false;
  double gravity = 0.02;

  Octopus({required super.position}) {
    add(RectangleHitbox(position: Vector2(7, 13), size: Vector2(18, 20)));
  }

  @override
  void update(double dt) {
    speedY = speedY * (1 + gravity);
    position.add(Vector2(speedX, speedY) * dt);
    super.update(dt);
  }

  @override
  Future<void>? onLoad() async {
    playerInfoEvents.subscribe((args) {
      playerInfoArgs = args;
    });

    size = textureSize;
    final motionless = await gameRef.loadSpriteAnimation(
      'octopus.png',
      SpriteAnimationData.sequenced(
        amount: 1,
        textureSize: textureSize,
        texturePosition: Vector2(0, 0),
        stepTime: 0.5,
      ),
    );
    final running = await gameRef.loadSpriteAnimation(
      'octopus.png',
      SpriteAnimationData.sequenced(
        amount: 2,
        textureSize: textureSize,
        texturePosition: Vector2(30, 0),
        stepTime: 0.1,
      ),
    );
    animations = {
      OctopusStates.running: running,
      OctopusStates.motionless: motionless,
    };

    current = OctopusStates.motionless;
    return super.onLoad();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Lance) {
      other.die();
    }
    if (other is Wall && !collided) {
      collided = true;
      speedY = 0;
      if (playerInfoArgs == null) {
        speedX = 100;
      } else if (playerInfoArgs!.position.x > position.x) {
        flipHorizontally();
        speedX = 100;
      } else {
        speedX = -100;
      }
      current = OctopusStates.running;
    }
    if (other is Bullet) {
      removeFromParent();
      other.removeFromParent();
    }
    if (other is ContraScreenHitbox) {
      other.removeFromParent();
    }
    super.onCollision(intersectionPoints, other);
  }
}
