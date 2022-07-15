import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import 'bullet.dart';

class SpriteBullet extends SpriteComponent
    with CollisionCallbacks, HasGameRef
    implements Bullet {
  Vector2 velocity;
  Vector2 collisionSize;
  Vector2 collisionPosition;
  Vector2 spriteSize;
  String path;

  SpriteBullet({
    required this.collisionSize,
    required this.collisionPosition,
    required this.velocity,
    required this.spriteSize,
    required this.path,
    required super.position,
    required super.size,
  }) {
    add(RectangleHitbox(position: collisionPosition, size: collisionSize));
  }

  @override
  Future<void>? onLoad() async {
    sprite = await gameRef.loadSprite(path, srcSize: spriteSize);
    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.add(velocity * dt);
  }
}
