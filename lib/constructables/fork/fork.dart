import 'dart:async';

import 'package:contra/player/player.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart' hide Timer;

enum ForkStates {
  first,
  second,
  third,
  fourth,
  fifth,
  sixth,
  seventh,
}

const double _stepTime = 0.5;

class Fork extends SpriteAnimationGroupComponent
    with HasGameRef, CollisionCallbacks {
  bool delayed;
  final _hitboxes = {
    ForkStates.first: Vector2(15, 33),
    ForkStates.second: Vector2(15, 41),
    ForkStates.third: Vector2(15, 49),
    ForkStates.fourth: Vector2(15, 57),
    ForkStates.fifth: Vector2(15, 65),
    ForkStates.sixth: Vector2(15, 73),
    ForkStates.seventh: Vector2(15, 81),
  };

  Fork({required super.position, required this.delayed}) {
    size = Vector2(15, 105);
    add(RectangleHitbox(
        position: Vector2.zero(), size: _hitboxes[ForkStates.first]));
  }

  @override
  Future<void>? onLoad() async {
    var textureSize = Vector2(15, 105);
    final first = await gameRef.loadSpriteAnimation(
      'fork.png',
      SpriteAnimationData.sequenced(
        amount: 1,
        textureSize: textureSize,
        texturePosition: Vector2(0, 0),
        stepTime: _stepTime,
      ),
    );

    final second = await gameRef.loadSpriteAnimation(
      'fork.png',
      SpriteAnimationData.sequenced(
        amount: 1,
        textureSize: textureSize,
        texturePosition: Vector2(15, 0),
        stepTime: _stepTime,
      ),
    );

    final third = await gameRef.loadSpriteAnimation(
      'fork.png',
      SpriteAnimationData.sequenced(
        amount: 1,
        textureSize: textureSize,
        texturePosition: Vector2(30, 0),
        stepTime: _stepTime,
      ),
    );

    final fourth = await gameRef.loadSpriteAnimation(
      'fork.png',
      SpriteAnimationData.sequenced(
        amount: 1,
        textureSize: textureSize,
        texturePosition: Vector2(45, 0),
        stepTime: _stepTime,
      ),
    );

    final fifth = await gameRef.loadSpriteAnimation(
      'fork.png',
      SpriteAnimationData.sequenced(
        amount: 1,
        textureSize: textureSize,
        texturePosition: Vector2(60, 0),
        stepTime: _stepTime,
      ),
    );

    final sixth = await gameRef.loadSpriteAnimation(
      'fork.png',
      SpriteAnimationData.sequenced(
        amount: 1,
        textureSize: textureSize,
        texturePosition: Vector2(75, 0),
        stepTime: _stepTime,
      ),
    );

    final seventh = await gameRef.loadSpriteAnimation(
      'fork.png',
      SpriteAnimationData.sequenced(
        amount: 1,
        textureSize: textureSize,
        texturePosition: Vector2(90, 0),
        stepTime: _stepTime,
      ),
    );

    animations = {
      ForkStates.first: first,
      ForkStates.second: second,
      ForkStates.third: third,
      ForkStates.fourth: fourth,
      ForkStates.fifth: fifth,
      ForkStates.sixth: sixth,
      ForkStates.seventh: seventh,
    };

    current = ForkStates.first;

    if (delayed) {
      Timer(const Duration(milliseconds: 800), () {
        _setupTimer();
      });
    } else {
      _setupTimer();
    }
    return super.onLoad();
  }

  void _setupTimer() {
    int i = 1;
    final indix = [0, 1, 2, 3, 4, 5, 6, 5, 4, 3, 2, 1];
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      var query = children.query<RectangleHitbox>();
      query[0].removeFromParent();
      current = ForkStates.values[indix[i]];
      var hitBox = _hitboxes[current];
      add(RectangleHitbox(position: Vector2.zero(), size: hitBox));
      i = (i + 1) % indix.length;
    });
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Lance) {
      other.die();
    }
    super.onCollision(intersectionPoints, other);
  }
}
