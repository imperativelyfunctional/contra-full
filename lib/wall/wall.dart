import 'package:contra/events/event.dart';
import 'package:contra/main.dart';
import 'package:contra/player/player.dart';
import 'package:contra/player/wall_sensor.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/geometry.dart';

enum WallType {
  fortress,
  bridge,
  water,
  rock;

  static WallType fromString(String type) {
    return values.firstWhere((e) => e.name.toString() == type);
  }
}

class Wall extends PositionComponent with CollisionCallbacks {
  final WallType type;

  Wall(this.type, {required super.position, required super.size}) {
    add(RectangleHitbox(position: Vector2.zero(), size: size));
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Lance) {
      var hitBoxes = other.children.query<RectangleHitbox>();
      if (hitBoxes.isNotEmpty && type != WallType.fortress) {
        var hitBox = hitBoxes.first;
        Vector2 hitBoxTopLeft = other.position + hitBox.position;
        var lineWidth = hitBox.width;
        var lineHeight = hitBox.height;
        var bottomLine = LineSegment(
            Vector2(hitBoxTopLeft.x, hitBoxTopLeft.y + lineHeight),
            Vector2(hitBoxTopLeft.x + lineWidth, hitBoxTopLeft.y + lineHeight));

        var rect = toRect();
        if (rect.intersectsLineSegment(bottomLine)) {
          touchWallEvents.broadcast(TouchWallArgs(true, type, position));
        }
      }
    }

    if (other is WallSensor && type == WallType.water) {
      touchWaterEvents.broadcast(TouchWallArgs(true, WallType.water, position));
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);
    if (other is WallSensor && type == WallType.water) {
      touchWaterEvents
          .broadcast(TouchWallArgs(false, WallType.water, position));
    }
  }
}
