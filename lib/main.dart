import 'dart:async';
import 'dart:math' show pi, Random;

import 'package:contra/bullets/bullet.dart';
import 'package:contra/collectables/flying_weapon.dart';
import 'package:contra/collectables/weapon.dart';
import 'package:contra/enemy/giant/giant.dart';
import 'package:contra/enemy/octopus.dart';
import 'package:contra/enemy/worms/worm.dart';
import 'package:contra/events/event.dart';
import 'package:contra/player/player.dart';
import 'package:contra/player/player_states.dart';
import 'package:contra/wall/screen_hitbox.dart';
import 'package:contra/wall/wall.dart';
import 'package:event/event.dart';
import 'package:flame/camera.dart';
import 'package:flame/components.dart' hide Timer;
import 'package:flame/experimental.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/particles.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tiled/tiled.dart' show ObjectGroup;

import 'constructables/fork/fork.dart';
import 'constructables/moving_flame.dart';
import 'enemy/flying_face/flying_face.dart';

const worldWidth = 4800.0;
const worldHeight = 240.0;
const ogViewPortHeight = 240.0;
const ogViewPortWidth = 256.0;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Flame.device.setLandscape();
  await Flame.device.fullScreen();
  var contra = Contra();
  runApp(GameWidget(game: contra));
}

final keyEvents = Event<KeyEventArgs>();
final touchWaterEvents = Event<TouchWallArgs>();
final touchWallEvents = Event<TouchWallArgs>();
final inAirEvents = Event<InAirArgs>();
final weaponDropEvents = Event<WeaponDropPositionArgs>();
final weaponTypeEvents = Event<WeaponTypeArgs>();
final spawnEvents = Event();

class Contra extends FlameGame with KeyboardEvents, HasCollisionDetection {
  late Timer cameraTimer;
  late Lance player;
  late PlayerInfoArgs playerInfoArgs;
  late double viewPortWidth;
  late double flyingFaceShowX;
  late double flyingFaceHideX;
  late double giantShowX;
  late double giantHideX;
  Giant? giant;
  List<FlyingFace> flyingFaces = [];
  WeaponType _weaponType = WeaponType.rifle;
  Worm? worm;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    viewPortWidth = size.x * ogViewPortWidth / size.y;
    camera.viewport = FixedResolutionViewport(
      resolution: Vector2(viewPortWidth, ogViewPortHeight),
    );
    var map = await TiledComponent.load('map.tmx', Vector2.all(16));
    world.add(map);
    for (var object
        in map.tileMap.getLayer<ObjectGroup>('collisions')!.objects) {
      world.add(Wall(WallType.fromString(object.type),
          position: Vector2(object.x, object.y),
          size: Vector2(object.width, object.height)));
    }

    for (var object
        in map.tileMap.getLayer<ObjectGroup>('positions')!.objects) {
      var name = object.name;
      var x = object.x;
      if (name == 'flying_faces_show') {
        flyingFaceShowX = x;
      } else if (name == 'flying_faces_hide') {
        flyingFaceHideX = x;
      } else if (name == "fork") {
        world.add(Fork(
            position: Vector2(x, object.y), delayed: object.type == 'delayed'));
      } else if (name == 'giant_show') {
        giantShowX = x;
      } else if (name == 'giant_hide') {
        giantHideX = x;
      }
    }
    player = Lance(
      'player.png',
      position: Vector2(30, 0),
      size: Vector2(41, 42),
    );
    await world.add(player);

    var flyWeaponAnimation = await loadSpriteAnimation(
        'flying_weapon.png',
        SpriteAnimationData.sequenced(
          amount: 2,
          textureSize: Vector2(24, 24),
          texturePosition: Vector2(0, 0),
          stepTime: 0.3,
        ));

    Timer.periodic(const Duration(seconds: 5), (timer) {
      world.add(FlyingObject(
          initialPosition: Vector2(camera.viewport.position.x - 60, 30),
          size: Vector2(24, 24),
          animation: flyWeaponAnimation));
    });

    Sprite life = await loadSprite('life.png', srcSize: Vector2(8, 16));
    camera.viewport.addAll([
      SpriteComponent(sprite: life, position: Vector2(20, 0), priority: 1),
      SpriteComponent(sprite: life, position: Vector2(35, 0), priority: 1),
      SpriteComponent(sprite: life, position: Vector2(50, 0), priority: 1),
      SpriteComponent(sprite: life, position: Vector2(65, 0), priority: 1)
    ]);

    world.add(ContraScreenHitbox());
    spawnEvents.subscribe((args) {
      player = Lance(
        'player.png',
        position: Vector2(camera.viewport.position.x + 30, 0),
        size: Vector2(41, 42),
      );
      world.add(player);
    });

    world.add(MovingFlame(
        position: Vector2(768 + 8, 102 + 8),
        destination: Vector2(880 + 8, 102 + 8)));
    world.add(MovingFlame(
        position: Vector2(880 + 8, 102 + 8),
        destination: Vector2(768 + 8, 102 + 8)));
    weaponDropEvents.subscribe((args) async {
      var weaponType = args!.weaponType;
      switch (weaponType) {
        case WeaponType.machine_gun:
          world.add(Weapon.machineGun(
              position: args.position,
              animation: await loadSpriteAnimation(
                'weapons.png',
                SpriteAnimationData.sequenced(
                  amount: 2,
                  textureSize: Vector2(24, 15),
                  texturePosition: Vector2(0, 0),
                  stepTime: stepTimeFast15,
                ),
              )));
          break;
        case WeaponType.spread_gun:
          world.add(Weapon.spreadGun(
              position: args.position,
              animation: await loadSpriteAnimation(
                'weapons.png',
                SpriteAnimationData.sequenced(
                  amount: 2,
                  textureSize: Vector2(24, 15),
                  texturePosition: Vector2(0, 45),
                  stepTime: stepTimeFast15,
                ),
              )));
          break;
        case WeaponType.fire_thrower:
          world.add(Weapon.fireThrower(
              position: args.position,
              animation: await loadSpriteAnimation(
                'weapons.png',
                SpriteAnimationData.sequenced(
                  amount: 2,
                  textureSize: Vector2(24, 15),
                  texturePosition: Vector2(0, 30),
                  stepTime: stepTimeFast15,
                ),
              )));
          break;
        default:
          break;
      }
    });

    weaponTypeEvents.subscribe((args) {
      _weaponType = args!.weaponType;
    });

    playerInfoEvents.subscribe((args) {
      playerInfoArgs = args!;
    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    var cameraXPos = camera.viewport.position.x;
    if (cameraXPos >= worldWidth - viewPortWidth && worm == null) {
      worm = Worm(position: Vector2(cameraXPos, 0));
      world.add(worm!);
      Timer.periodic(const Duration(milliseconds: 600), (timer) {
        Random random = Random();

        world.add(Octopus(
            position:
                Vector2(random.nextDouble() * cameraXPos + cameraXPos, 1)));
        world.add(Octopus(
            position:
                Vector2(random.nextDouble() * cameraXPos + cameraXPos, 1)));
      });
    }
    if (cameraXPos < worldWidth - viewPortWidth) {
      camera.setBounds(Rectangle.fromLTWH(
          cameraXPos, 0, worldWidth - cameraXPos, worldHeight));
      camera.follow(
        player,
      );
    }

    if (cameraXPos >= flyingFaceShowX && flyingFaces.isEmpty) {
      var leftFace = FlyingFace(
        position: Vector2(size.x / 4, 20),
        destination: Vector2(size.x * 3 / 4, 20),
      );
      flyingFaces.add(leftFace);
      world.add(leftFace);
      var middleFace = FlyingFace(
        position: Vector2(size.x * 3 / 4, 20),
        destination: Vector2(size.x / 4, 20),
      );
      flyingFaces.add(middleFace);
      world.add(middleFace);
      var rightFace = FlyingFace(
        position: Vector2(size.x * 2 / 4, 20),
        destination: Vector2(size.x * 2 / 4, 20),
      );
      flyingFaces.add(rightFace);
      world.add(rightFace);
    }

    if (cameraXPos >= giantShowX && giant == null) {
      giant = Giant(
          position: Vector2(cameraXPos + viewPortWidth * 3 / 4, 161 - 62),
          speedX: 50);
      world.add(giant!);
    } else if (cameraXPos >= giantHideX) {
      giant!.removeFromParent();
    }

    if (cameraXPos >= flyingFaceHideX) {
      for (var element in flyingFaces) {
        element.removeFromParent();
      }
    }
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    {
      if (keysPressed.isNotEmpty) {
        for (var element in keysPressed) {
          keyEvents.broadcast(KeyEventArgs(element, true));
        }
        if (keysPressed.contains(LogicalKeyboardKey.keyJ) && !player.dead) {
          _fire();
        }
      }

      if (event is KeyUpEvent) {
        keyEvents.broadcast(KeyEventArgs(event.logicalKey, false));
        if (event.logicalKey == LogicalKeyboardKey.keyJ) {}
      }
      return super.onKeyEvent(event, keysPressed);
    }
  }

  Future<void> _fire() async {
    if (player.current != PlayerStates.rightUnderWater &&
        player.current != PlayerStates.rightUnderWater) {
      var fireVelocity = _fireVelocity(player.current!, 400);
      var bullet = Bullet(
          _weaponType,
          playerInfoArgs.position + barrel[playerInfoArgs.playerState]!,
          fireVelocity.first,
          fireVelocity.second);
      world.add(bullet);
    }
  }
}

class Tuple<T1, T2> {
  final T1 first;
  final T2 second;

  Tuple({
    required this.first,
    required this.second,
  });
}

Tuple<Vector2, double> _fireVelocity(
    PlayerStates playerStates, double positiveSpeed) {
  switch (playerStates) {
    case PlayerStates.waterLeftIdle:
      return Tuple(first: Vector2(-positiveSpeed, 0), second: pi);
    case PlayerStates.waterRightIdle:
      return Tuple(first: Vector2(positiveSpeed, 0), second: 0);
    case PlayerStates.waterLeftShoot:
      return Tuple(first: Vector2(-positiveSpeed, 0), second: pi);
    case PlayerStates.waterRightShoot:
      return Tuple(first: Vector2(positiveSpeed, 0), second: 0);
    case PlayerStates.waterLeftStraightUp:
      return Tuple(first: Vector2(0, -positiveSpeed), second: -pi / 2);
    case PlayerStates.waterRightStraightUp:
      return Tuple(first: Vector2(0, -positiveSpeed), second: -pi / 2);
    case PlayerStates.waterLeftUp:
      return Tuple(
          first: Vector2(-positiveSpeed, -positiveSpeed), second: 5 * pi / 4);
    case PlayerStates.waterRightUp:
      return Tuple(
          first: Vector2(positiveSpeed, -positiveSpeed), second: -pi / 4);
    case PlayerStates.leftRunShoot:
      return Tuple(first: Vector2(-positiveSpeed, 0), second: pi);
    case PlayerStates.rightRunShoot:
      return Tuple(first: Vector2(positiveSpeed, 0), second: 0);
    case PlayerStates.leftUp:
      return Tuple(
          first: Vector2(-positiveSpeed, -positiveSpeed), second: 5 * pi / 4);
    case PlayerStates.rightUp:
      return Tuple(
          first: Vector2(positiveSpeed, -positiveSpeed), second: -pi / 4);
    case PlayerStates.leftUpJump:
      return Tuple(
          first: Vector2(-positiveSpeed, -positiveSpeed), second: 5 * pi / 4);
    case PlayerStates.rightUpJump:
      return Tuple(
          first: Vector2(positiveSpeed, -positiveSpeed), second: -pi / 4);
    case PlayerStates.leftDownJump:
      return Tuple(
          first: Vector2(-positiveSpeed, positiveSpeed), second: 3 * pi / 4);
    case PlayerStates.rightDownJump:
      return Tuple(
          first: Vector2(positiveSpeed, positiveSpeed), second: pi / 4);
    case PlayerStates.leftStraightUpJump:
      return Tuple(first: Vector2(0, -positiveSpeed), second: -pi / 2);
    case PlayerStates.rightStraightUpJump:
      return Tuple(first: Vector2(0, -positiveSpeed), second: -pi / 2);
    case PlayerStates.leftStraightUpJumpNoKey:
      return Tuple(first: Vector2(-positiveSpeed, 0), second: pi);
    case PlayerStates.rightStraightUpJumpNoKey:
      return Tuple(first: Vector2(positiveSpeed, 0), second: 0);
    case PlayerStates.leftJump:
      return Tuple(first: Vector2(-positiveSpeed, 0), second: pi);
    case PlayerStates.rightJump:
      return Tuple(first: Vector2(positiveSpeed, 0), second: 0);
    case PlayerStates.leftStraightUp:
      return Tuple(first: Vector2(0, -positiveSpeed), second: -pi / 2);
    case PlayerStates.rightStraightUp:
      return Tuple(first: Vector2(0, -positiveSpeed), second: -pi / 2);
    case PlayerStates.leftStraightDown:
      return Tuple(first: Vector2(-positiveSpeed, 0), second: pi);
    case PlayerStates.rightStraightDown:
      return Tuple(first: Vector2(positiveSpeed, 0), second: 0);
    case PlayerStates.leftStraightDownJump:
      return Tuple(first: Vector2(0, positiveSpeed), second: pi / 2);
    case PlayerStates.rightStraightDownJump:
      return Tuple(first: Vector2(0, positiveSpeed), second: pi / 2);
    case PlayerStates.leftDown:
      return Tuple(
          first: Vector2(-positiveSpeed, positiveSpeed), second: 3 * pi / 4);
    case PlayerStates.rightDown:
      return Tuple(
          first: Vector2(positiveSpeed, positiveSpeed), second: pi / 4);
    case PlayerStates.leftIdle:
      return Tuple(first: Vector2(-positiveSpeed, 0), second: pi);
    case PlayerStates.rightIdle:
      return Tuple(first: Vector2(positiveSpeed, 0), second: 0);
    default:
      return Tuple(first: Vector2.zero(), second: 0);
  }
}
