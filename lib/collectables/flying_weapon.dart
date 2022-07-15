import 'dart:async';
import 'dart:math';

import 'package:contra/bullets/bullet.dart';
import 'package:contra/collectables/weapon.dart';
import 'package:contra/events/event.dart';
import 'package:contra/main.dart';
import 'package:contra/wall/screen_hitbox.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart' hide Timer;

class FlyingObject extends SpriteAnimationComponent
    with CollisionCallbacks, HasGameRef {
  Vector2 initialPosition;
  double jumpHeight = 2;
  double radian = 0;
  late Timer timer;
  final Random _random = Random();
  bool _enableCollisionWithScreen = false;

  FlyingObject(
      {required this.initialPosition,
      required super.size,
      required super.animation}) {
    position = initialPosition;
    add(RectangleHitbox(size: Vector2(13, 9), position: Vector2(5, 2)));
    Timer(const Duration(seconds: 2), () {
      _enableCollisionWithScreen = true;
    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    radian += (pi / 60) * dt * 100;
    position.add(Vector2(2, sin(radian) * jumpHeight));
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Bullet) {
      removeFromParent();
      other.removeFromParent();
      weaponDropEvents.broadcast(WeaponDropPositionArgs(position,
          WeaponType.values[_random.nextInt(WeaponType.values.length - 1)]));
    }
    if (other is ContraScreenHitbox && _enableCollisionWithScreen) {
      removeFromParent();
    }
  }
}
