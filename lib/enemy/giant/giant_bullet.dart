import 'package:contra/player/player.dart';
import 'package:contra/wall/screen_hitbox.dart';
import 'package:contra/wall/wall.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

class GiantBullet extends SpriteAnimationComponent
    with HasGameRef, CollisionCallbacks {
  final Vector2 velocity;

  GiantBullet({required super.position, required this.velocity}) {
    size = Vector2(18, 11);
    add(RectangleHitbox(size: size));
  }

  @override
  Future<void>? onLoad() async {
    animation = await gameRef.loadSpriteAnimation(
        'giant_bullet.png',
        SpriteAnimationData.sequenced(
          amount: 2,
          textureSize: Vector2(18, 11),
          stepTime: 0.1,
        ));
    return super.onLoad();
  }

  @override
  void update(double dt) {
    position.add(velocity * dt);
    super.update(dt);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Wall) {
      velocity.y = 0;
    }
    if (other is Lance) {
      other.die();
    }
    if (other is ContraScreenHitbox) {
      removeFromParent();
    }
    super.onCollision(intersectionPoints, other);
  }
}
