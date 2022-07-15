import 'package:contra/bullets/spread_animated_bullet.dart';
import 'package:contra/bullets/sprite_bullet.dart';
import 'package:contra/collectables/weapon.dart';
import 'package:flame/components.dart';

import 'fire_thrower.dart';

abstract class Bullet extends PositionComponent {
  factory Bullet(WeaponType weaponType, Vector2 position, Vector2 velocity,
      double radian) {
    switch (weaponType) {
      case WeaponType.rifle:
        return SpriteBullet(
          collisionSize: Vector2(3, 3),
          collisionPosition: Vector2.zero(),
          velocity: velocity,
          position: position,
          size: Vector2(3, 3),
          path: 'b1.png',
          spriteSize: Vector2(3, 3),
        )..anchor = Anchor.center;
      case WeaponType.machine_gun:
        return SpriteBullet(
          collisionSize: Vector2(5, 5),
          collisionPosition: Vector2.zero(),
          velocity: velocity,
          position: position,
          size: Vector2(5, 5),
          path: 'b2.png',
          spriteSize: Vector2(5, 5),
        )..anchor = Anchor.center;
      case WeaponType.spread_gun:
        return SpreadBullets(radian: radian, speed: 300, position: position);
      case WeaponType.fire_thrower:
        return FireThrowerBullets(
            angleChange: 10, velocity: velocity, position: position);
      default:
        break;
    }
    throw '';
  }
}
