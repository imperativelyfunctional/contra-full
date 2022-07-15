import 'package:contra/player/player.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';

class MovingFlame extends SpriteAnimationComponent
    with HasGameRef, CollisionCallbacks {
  final Vector2 destination;
  final Vector2 spriteSize = Vector2(16, 16);

  MovingFlame({required super.position, required this.destination}) {
    add(RectangleHitbox(size: spriteSize));
  }

  @override
  Future<void>? onLoad() async {
    size = spriteSize;
    anchor = Anchor.center;
    animation = await gameRef.loadSpriteAnimation(
        'fire.png',
        SpriteAnimationData.sequenced(
            amount: 2, stepTime: 0.1, textureSize: spriteSize));
    add(MoveToEffect(destination,
        EffectController(infinite: true, duration: 2, reverseDuration: 2)));
    return super.onLoad();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Lance) {
      other.die();
    }
  }
}
