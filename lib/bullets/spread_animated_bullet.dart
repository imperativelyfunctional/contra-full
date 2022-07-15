import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import 'bullet.dart';

class SpriteAnimatedBullet extends SpriteAnimationComponent
    with CollisionCallbacks, HasGameRef
    implements Bullet {
  Vector2 velocity;
  Vector2 collisionSize;
  Vector2 collisionPosition;
  Vector2 textureSize;
  Vector2 texturePosition;
  String path;
  int amount;
  double stepTime;
  bool loop;

  SpriteAnimatedBullet(
      {required this.collisionSize,
      required this.collisionPosition,
      required this.velocity,
      required this.textureSize,
      required this.texturePosition,
      required this.path,
      required this.amount,
      required this.stepTime,
      required this.loop,
      required super.position,
      required super.size}) {
    add(RectangleHitbox(position: collisionPosition, size: collisionSize));
  }

  @override
  Future<void>? onLoad() async {
    animation = await gameRef.loadSpriteAnimation(
        path,
        SpriteAnimationData.sequenced(
          amount: amount,
          textureSize: textureSize,
          texturePosition: texturePosition,
          stepTime: stepTime,
          loop: loop,
        ));
    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.add(velocity * dt);
  }
}

class SpreadBullets extends PositionComponent
    with HasGameRef
    implements Bullet {
  final double radian;
  final double speed;
  final spriteSize = Vector2(8, 8);
  final spritePath = 'b3.png';
  final amount = 2;
  var stepTime = 0.2;

  SpreadBullets(
      {required super.position, required this.radian, required this.speed});

  SpriteAnimatedBullet _generate(double radian) {
    return SpriteAnimatedBullet(
      collisionSize: spriteSize,
      collisionPosition: Vector2.zero(),
      velocity: _moveWithAngle(radian, speed),
      position: position,
      size: spriteSize,
      path: spritePath,
      textureSize: spriteSize,
      loop: false,
      stepTime: stepTime,
      amount: amount,
      texturePosition: Vector2.zero(),
    )..anchor = Anchor.center;
  }

  @override
  Future<void>? onLoad() async {
    gameRef.add(_generate(radian));
    for (int i = 1; i < 5; i++) {
      gameRef.add(_generate(radian + i * pi / 36));
      gameRef.add(_generate(radian - i * pi / 36));
    }
    return super.onLoad();
  }

  Vector2 _moveWithAngle(num radians, double speed) {
    return Vector2(cos(radians), sin(radians)) * speed;
  }
}
