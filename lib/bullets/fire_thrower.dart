import 'package:contra/bullets/sprite_bullet.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';

import 'bullet.dart';

class FireThrowerBullets extends PositionComponent
    with HasGameRef
    implements Bullet {
  final double angleChange;
  final Vector2 velocity;

  FireThrowerBullets(
      {required this.angleChange,
      required this.velocity,
      required super.position});

  @override
  Future<void>? onLoad() {
    size = Vector2.zero();
    anchor = Anchor.center;
    addBullet(Vector2(10, 0));
    addBullet(Vector2(-10, 0));
    addBullet(Vector2(0, 10));
    addBullet(Vector2(0, -10));
    return super.onLoad();
  }

  void addBullet(Vector2 position) {
    add(SpriteBullet(
        collisionSize: Vector2(8, 8),
        collisionPosition: Vector2.zero(),
        velocity: Vector2.zero(),
        spriteSize: Vector2(8, 8),
        path: 'b4.png',
        position: position,
        size: Vector2(8, 8))
      ..anchor = Anchor.center);
  }

  @override
  void update(double dt) {
    angle += angleChange * dt;
    position.add(velocity.normalized() * 200 * dt);
    super.update(dt);
  }
}
