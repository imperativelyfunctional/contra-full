import 'package:contra/bullets/bullet.dart';
import 'package:flame/components.dart';

class ContraScreenHitbox extends ScreenHitbox {
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Bullet) {
      other.removeFromParent();
    }
    super.onCollision(intersectionPoints, other);
  }
}
