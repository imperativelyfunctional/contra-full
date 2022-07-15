import 'package:contra/events/event.dart';
import 'package:contra/main.dart';
import 'package:contra/wall/wall.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

class WallSensor extends RectangleComponent
    with CollisionCallbacks, HasGameRef {
  WallSensor({super.position, super.size}) {
    add(RectangleHitbox(position: Vector2.zero(), size: size));
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Wall && other.type != WallType.fortress) {
      inAirEvents.broadcast(InAirArgs(false));
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);
    if (other is Wall && other.type != WallType.fortress) {
      inAirEvents.broadcast(InAirArgs(true));
    }
  }
}
