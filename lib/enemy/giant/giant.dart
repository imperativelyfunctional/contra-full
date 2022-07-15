import 'dart:async';
import 'dart:math';

import 'package:contra/bullets/bullet.dart';
import 'package:contra/player/player.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart' hide Timer;
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

import '../../events/event.dart';
import 'giant_bullet.dart';

enum GiantStates {
  standLeft,
  standRight,
  walkLeft,
  walkRight,
  shootLeft,
  shootRight,
}

class Giant extends SpriteAnimationGroupComponent
    with HasGameRef, CollisionCallbacks {
  double speedX;
  late List<Particle> particles;
  bool shoot = false;
  bool facingLeft = true;
  int life = 20;
  PlayerInfoArgs? playerInfoArgs;
  GiantStates _currentState = GiantStates.standLeft;
  final textureSize = Vector2(60, 62);
  final List<Timer> _timers = [];

  Giant({required super.position, required this.speedX}) {
    add(RectangleHitbox(
        position: Vector2((60 - 23) / 2, (62 - 44) / 2),
        size: Vector2(23, 44)));
  }

  @override
  void update(double dt) {
    var currentString = _currentState.toString();
    if (playerInfoArgs != null) {
      var playerPosition = playerInfoArgs!.position;
      if (playerPosition.x < position.x) {
        facingLeft = true;
      } else {
        facingLeft = false;
      }
    }
    if (currentString.contains('walk')) {
      if (facingLeft) {
        current = GiantStates.walkLeft;
      } else {
        current = GiantStates.walkRight;
      }
      position.add(Vector2(facingLeft ? -speedX : speedX, 0) * dt);
      shoot = false;
    }
    if (currentString.contains('stand')) {
      if (facingLeft) {
        current = GiantStates.standLeft;
      } else {
        current = GiantStates.standRight;
      }
      shoot = false;
    }
    if (currentString.contains('shoot')) {
      if (facingLeft) {
        current = GiantStates.shootLeft;
      } else {
        current = GiantStates.shootRight;
      }
      shoot = true;
    }
    if (life <= 0) {
      die();
    }
    super.update(dt);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Lance) {
      other.die();
    } else if (other is Bullet) {
      other.removeFromParent();
      life--;
    }

    super.onCollision(intersectionPoints, other);
  }

  @override
  Future<void>? onLoad() async {
    playerInfoEvents.subscribe((args) {
      playerInfoArgs = args;
    });
    var timer = Timer.periodic(const Duration(milliseconds: 750), (timer) {
      if (shoot) {
        gameRef.add(GiantBullet(
            position: position + Vector2(width / 2, 0),
            velocity: Vector2(facingLeft ? -1 : 1, 1).normalized() * 200));
      }
    });
    _timers.add(timer);
    particles = await imageParticle();
    Random random = Random();
    var timer2 = Timer.periodic(const Duration(seconds: 2), (timer) {
      _currentState =
          GiantStates.values[random.nextInt(GiantStates.values.length)];
    });
    _timers.add(timer2);
    size = textureSize;
    final standLeft = await gameRef.loadSpriteAnimation(
      'giant.png',
      SpriteAnimationData.sequenced(
        amount: 1,
        textureSize: textureSize,
        texturePosition: Vector2(60 * 3, 0),
        stepTime: 0.5,
      ),
    );
    final walkLeft = await gameRef.loadSpriteAnimation(
      'giant.png',
      SpriteAnimationData.sequenced(
        amount: 2,
        textureSize: textureSize,
        texturePosition: Vector2(60 * 3, 0),
        stepTime: 0.5,
      ),
    );
    final standRight = await gameRef.loadSpriteAnimation(
      'giant.png',
      SpriteAnimationData.sequenced(
        amount: 1,
        textureSize: textureSize,
        texturePosition: Vector2(0, 0),
        stepTime: 0.5,
      ),
    );
    final walkRight = await gameRef.loadSpriteAnimation(
      'giant.png',
      SpriteAnimationData.sequenced(
        amount: 2,
        textureSize: textureSize,
        texturePosition: Vector2(0, 0),
        stepTime: 0.5,
      ),
    );
    final shootLeft = await gameRef.loadSpriteAnimation(
      'giant.png',
      SpriteAnimationData.sequenced(
        amount: 1,
        textureSize: textureSize,
        texturePosition: Vector2(300, 0),
        stepTime: 0.5,
      ),
    );
    final shootRight = await gameRef.loadSpriteAnimation(
      'giant.png',
      SpriteAnimationData.sequenced(
        amount: 1,
        textureSize: textureSize,
        texturePosition: Vector2(120, 0),
        stepTime: 0.5,
      ),
    );

    animations = {
      GiantStates.standLeft: standLeft,
      GiantStates.walkLeft: walkLeft,
      GiantStates.standRight: standRight,
      GiantStates.walkRight: walkRight,
      GiantStates.shootLeft: shootLeft,
      GiantStates.shootRight: shootRight,
    };
    current = GiantStates.standLeft;
    return super.onLoad();
  }

  @override
  void removeFromParent() {
    super.removeFromParent();
    for (var element in _timers) {
      element.cancel();
    }
  }

  void die() {
    removeFromParent();
    gameRef.add(
      ParticleSystemComponent(
          particle: TranslatedParticle(
        lifespan: 6,
        offset: Vector2(width / 2, height / 2),
        child: acceleratedParticles(particles),
      ))
        ..position = position,
    );
  }

  Particle acceleratedParticles(List<Particle> particles) {
    Random rnd = Random();

    return Particle.generate(
        count: particles.length,
        generator: (i) => AcceleratedParticle(
              speed: Vector2(
                      rnd.nextDouble() * 600 - 300, -rnd.nextDouble() * 600) *
                  .2,
              acceleration: Vector2(0, 100),
              child: RotatingParticle(
                  from: rnd.nextDouble() * pi,
                  child: PaintParticle(
                      child: particles[i],
                      paint: Paint()
                        ..colorFilter = ColorFilter.mode(
                            Colors.amber.withOpacity(0.2), BlendMode.srcATop))),
            ));
  }

  Future<List<Particle>> imageParticle(
      {double rows = 5, double columns = 5}) async {
    List<Particle> particles = [];

    double width = 52 / columns;
    double height = 62 / rows;
    Vector2 size = Vector2(width, height);

    for (int i = 0; i < columns; i++) {
      for (int j = 0; j < rows; j++) {
        particles.add(SpriteParticle(
          size: size,
          sprite: await gameRef.loadSprite(
            'e1.png',
            srcSize: size,
            srcPosition: Vector2(i * width, j * height),
          ),
        ));
      }
    }
    return particles;
  }
}
