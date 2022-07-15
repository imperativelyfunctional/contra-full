import 'package:contra/events/event.dart';
import 'package:contra/main.dart';
import 'package:contra/player/player.dart';
import 'package:contra/wall/wall.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

enum WeaponType {
  machine_gun,
  spread_gun,
  fire_thrower,
  rifle,
}

class Weapon extends SpriteAnimationComponent with CollisionCallbacks {
  final WeaponType type;
  Vector2 velocity = Vector2(0, 1);

  Weapon(
      {required this.type, required super.animation, required super.position}) {
    add(RectangleHitbox(size: Vector2(24, 15)));
    super.size = Vector2(24, 15);
  }

  Weapon.machineGun({animation, position})
      : this(
          type: WeaponType.machine_gun,
          animation: animation,
          position: position,
        );

  Weapon.spreadGun({animation, position})
      : this(
          type: WeaponType.spread_gun,
          animation: animation,
          position: position,
        );

  Weapon.rifle({animation, position})
      : this(
          type: WeaponType.rifle,
          animation: animation,
          position: position,
        );

  Weapon.fireThrower({animation, position})
      : this(
          type: WeaponType.fire_thrower,
          animation: animation,
          position: position,
        );

  @override
  void update(double dt) {
    super.update(dt);
    position.add(velocity);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall) {
      velocity.x = 0;
      velocity.y = 0;
      position.y = other.y - size.y;
    }
    if (other is Lance) {
      weaponTypeEvents.broadcast(WeaponTypeArgs(type));
      removeFromParent();
    }
  }
}
