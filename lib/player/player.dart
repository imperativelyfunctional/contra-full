import 'dart:async';

import 'package:contra/collectables/weapon.dart';
import 'package:contra/events/event.dart';
import 'package:contra/main.dart';
import 'package:contra/player/player_states.dart';
import 'package:contra/player/wall_sensor.dart';
import 'package:event/event.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart' hide Timer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../wall/screen_hitbox.dart';
import '../wall/wall.dart';

const double horizontalSpeed = 70;
const double verticalSpeed = 120;
const double jumpHeight = 52;
const stepTimeFast15 = 0.1;
const stepTimeSlow30 = 0.3;
const double stepTimeSlow100 = 1;

final playerInfoEvents = Event<PlayerInfoArgs>();

class Lance extends SpriteAnimationGroupComponent<PlayerStates>
    with HasGameRef, CollisionCallbacks {
  final String path;
  final double cellWidth = 41;
  final double cellHeight = 42;
  double speedX = 0;
  double speedY = verticalSpeed;
  bool facingRight = true;
  bool enableWallCollisionDetection = true;
  bool touchingWater = false;
  bool inAir = true;
  bool jumping = false;
  bool jumpUp = false;
  double maximumHeight = 0;
  bool dead = false;
  bool adjustVerticalSpeed = true;
  late Vector2 initialPosition;
  final Map<LogicalKeyboardKey, bool> keyMap = {};

  Lance(
    this.path, {
    Paint? paint,
    required super.position,
    required super.size,
    int priority = 0,
  }) {
    initialPosition = super.position;
    keyMap[LogicalKeyboardKey.keyA] = false;
    keyMap[LogicalKeyboardKey.keyD] = false;
    keyMap[LogicalKeyboardKey.keyW] = false;
    keyMap[LogicalKeyboardKey.keyS] = false;
    keyMap[LogicalKeyboardKey.keyK] = false;
    keyEvents.subscribe((args) {
      keyMap[args!.key] = args.pressed;
    });
    touchWaterEvents.subscribe((args) {
      touchingWater = args!.touching && args.wallType == WallType.water;
    });
    inAirEvents.subscribe((args) {
      inAir = args!.inAir;
      if (!inAir && jumping) {
        if (jumpUp) {
          inAir = true;
        } else {
          jumping = false;
        }
      }
    });
    touchWallEvents.subscribe((args) {
      if (enableWallCollisionDetection && !jumping) {
        position.y = args!.wallPosition.y - height;
        speedY = verticalSpeed;
      }
      if (jumping && !jumpUp) {
        position.y = args!.wallPosition.y - height;
        speedY = verticalSpeed;
      }
    });
  }

  void _updateHitBox(PlayerStates playerState) {
    if (!playerState.name.contains('UnderWater')) {
      var query = children.query<RectangleHitbox>();
      query[0].removeFromParent();
      var hitBox = hitBoxes[playerState]!;
      add(RectangleHitbox(position: hitBox[0], size: hitBox[1]));
    }
    current = playerState;
  }

  bool _canGoDown() {
    var referenceBox = hitBoxes[PlayerStates.rightRunShoot]!;
    var referenceBoxPosition = referenceBox[0]!;
    var referenceBoxDimension = referenceBox[1]!;
    var left = position.x;
    var top =
        position.y + referenceBoxPosition.y + referenceBoxDimension.y + 12;
    var rect = Rect.fromLTWH(left + referenceBoxPosition.x, top,
        referenceBoxDimension.x, ogViewPortHeight - top);
    return gameRef.children
        .query<Wall>()
        .any((element) => element.toRect().overlaps(rect));
  }

  PlayerStates? _noKeys() {
    if (inAir) {
      if (jumping) {
        return facingRight
            ? PlayerStates.rightStraightUpJumpNoKey
            : PlayerStates.leftStraightUpJumpNoKey;
      }
    } else {
      if (touchingWater) {
        return facingRight
            ? PlayerStates.waterRightIdle
            : PlayerStates.waterLeftIdle;
      } else {
        return facingRight ? PlayerStates.rightIdle : PlayerStates.leftIdle;
      }
    }
    return null;
  }

  PlayerStates? _oneKey(LogicalKeyboardKey keyboardKey) {
    if (keyboardKey == LogicalKeyboardKey.keyA) {
      if (jumping) {
        return PlayerStates.leftJump;
      } else {
        return touchingWater
            ? PlayerStates.waterLeftShoot
            : PlayerStates.leftRunShoot;
      }
    }
    if (keyboardKey == LogicalKeyboardKey.keyD) {
      if (jumping) {
        return PlayerStates.rightJump;
      } else {
        return touchingWater
            ? PlayerStates.waterRightShoot
            : PlayerStates.rightRunShoot;
      }
    }
    if (keyboardKey == LogicalKeyboardKey.keyW) {
      if (!jumping) {
        return facingRight
            ? touchingWater
                ? PlayerStates.waterRightStraightUp
                : PlayerStates.rightStraightUp
            : touchingWater
                ? PlayerStates.waterLeftStraightUp
                : PlayerStates.leftStraightUp;
      } else {
        return facingRight
            ? PlayerStates.rightStraightUpJump
            : PlayerStates.leftStraightUpJump;
      }
    }
    if (keyboardKey == LogicalKeyboardKey.keyS) {
      if (inAir) {
        return facingRight
            ? PlayerStates.rightStraightDownJump
            : PlayerStates.leftStraightDownJump;
      } else {
        return facingRight
            ? touchingWater
                ? PlayerStates.rightUnderWater
                : PlayerStates.rightStraightDown
            : touchingWater
                ? PlayerStates.leftUnderWater
                : PlayerStates.leftStraightDown;
      }
    }
    if (keyboardKey == LogicalKeyboardKey.keyK && !inAir && !touchingWater) {
      jumping = true;
      jumpUp = true;
      maximumHeight = position.y - jumpHeight;
      return facingRight
          ? PlayerStates.rightStraightUpJump
          : PlayerStates.leftStraightUpJump;
    }
    return null;
  }

  PlayerStates? _twoKeys(Set<LogicalKeyboardKey> keyboardKeys) {
    if (keyboardKeys
        .containsAll([LogicalKeyboardKey.keyA, LogicalKeyboardKey.keyK])) {
      if (!inAir && !touchingWater) {
        jumping = true;
        jumpUp = true;
        maximumHeight = position.y - jumpHeight;
        return PlayerStates.leftJump;
      }
    }

    if (keyboardKeys
        .containsAll([LogicalKeyboardKey.keyD, LogicalKeyboardKey.keyK])) {
      if (!inAir && !touchingWater) {
        jumping = true;
        jumpUp = true;
        maximumHeight = position.y - jumpHeight;
        return PlayerStates.rightJump;
      }
    }

    if (keyboardKeys
        .containsAll([LogicalKeyboardKey.keyA, LogicalKeyboardKey.keyW])) {
      if (jumping) {
        return PlayerStates.leftUpJump;
      } else {
        return touchingWater ? PlayerStates.waterLeftUp : PlayerStates.leftUp;
      }
    }

    if (keyboardKeys
        .containsAll([LogicalKeyboardKey.keyA, LogicalKeyboardKey.keyS])) {
      if (jumping) {
        return PlayerStates.leftDownJump;
      } else {
        return touchingWater
            ? PlayerStates.waterLeftShoot
            : PlayerStates.leftDown;
      }
    }
    if (keyboardKeys
        .containsAll([LogicalKeyboardKey.keyW, LogicalKeyboardKey.keyD])) {
      if (jumping) {
        return PlayerStates.rightUpJump;
      } else {
        return touchingWater ? PlayerStates.waterRightUp : PlayerStates.rightUp;
      }
    }
    if (keyboardKeys
        .containsAll([LogicalKeyboardKey.keyS, LogicalKeyboardKey.keyD])) {
      if (jumping) {
        return PlayerStates.rightDownJump;
      } else {
        return touchingWater
            ? PlayerStates.waterRightShoot
            : PlayerStates.rightDown;
      }
    }
    if (keyboardKeys
            .containsAll([LogicalKeyboardKey.keyS, LogicalKeyboardKey.keyK]) &&
        _canGoDown() &&
        !inAir) {
      enableWallCollisionDetection = false;
      initialPosition = position.clone();
      return facingRight ? PlayerStates.rightIdle : PlayerStates.leftIdle;
    }
    if (keyboardKeys
        .containsAll([LogicalKeyboardKey.keyW, LogicalKeyboardKey.keyK])) {
      if (inAir) {
        return facingRight
            ? PlayerStates.rightStraightUpJump
            : PlayerStates.leftStraightUpJump;
      }
      if (!inAir && !touchingWater) {
        jumping = true;
        jumpUp = true;
        maximumHeight = position.y - jumpHeight;
        return facingRight
            ? PlayerStates.rightStraightUpJump
            : PlayerStates.leftStraightUpJump;
      }
    }

    if (keyboardKeys
            .containsAll([LogicalKeyboardKey.keyW, LogicalKeyboardKey.keyK]) &&
        !inAir &&
        !touchingWater) {
      jumping = true;
      jumpUp = true;
      maximumHeight = position.y - jumpHeight;
      return facingRight
          ? PlayerStates.rightStraightUpJump
          : PlayerStates.leftStraightUpJump;
    }
    return null;
  }

  PlayerStates? _threeKeys(Set<LogicalKeyboardKey> keyboardKeys) {
    var leftUpJump = keyboardKeys.containsAll([
      LogicalKeyboardKey.keyA,
      LogicalKeyboardKey.keyW,
      LogicalKeyboardKey.keyK
    ]);
    var leftDownJump = keyboardKeys.containsAll([
      LogicalKeyboardKey.keyA,
      LogicalKeyboardKey.keyS,
      LogicalKeyboardKey.keyK
    ]);
    if (leftUpJump || leftDownJump) {
      if (!inAir && !touchingWater) {
        jumping = true;
        jumpUp = true;
        maximumHeight = position.y - jumpHeight;
        return leftUpJump ? PlayerStates.leftUpJump : PlayerStates.leftDownJump;
      }
    }

    var rightUpJump = keyboardKeys.containsAll([
      LogicalKeyboardKey.keyD,
      LogicalKeyboardKey.keyW,
      LogicalKeyboardKey.keyK
    ]);
    var rightDownJump = keyboardKeys.containsAll([
      LogicalKeyboardKey.keyD,
      LogicalKeyboardKey.keyS,
      LogicalKeyboardKey.keyK
    ]);
    if (rightUpJump || rightDownJump) {
      if (!inAir && !touchingWater) {
        jumping = true;
        jumpUp = true;
        maximumHeight = position.y - jumpHeight;
        return rightUpJump
            ? PlayerStates.rightUpJump
            : PlayerStates.rightDownJump;
      }
    }
    return null;
  }

  PlayerStates? _calculateState() {
    var keys = keyMap.entries
        .where((element) => element.value)
        .map((e) => e.key)
        .toSet();
    switch (keys.length) {
      case 0:
        return _noKeys();
      case 1: // only one key is pressed
        return _oneKey(keys.first);
      case 2: // only two keys are pressed
        return _twoKeys(keys);
      case 3: // only two keys are pressed
        return _threeKeys(keys);
      default:
        break;
    }
    return null;
  }

  @override
  void update(double dt) async {
    if (!dead) {
      var latestState = _calculateState();
      if (latestState != null) {
        facingRight =
            (latestState.name.toLowerCase().contains('left')) ? false : true;
      }
      if (current != latestState && latestState != null) {
        _updateHitBox(latestState);
      }
      if (!enableWallCollisionDetection) {
        if (position.y - initialPosition.y >= 9) {
          enableWallCollisionDetection = true;
        }
      }
      switch (current) {
        case PlayerStates.rightRunShoot:
          speedX = horizontalSpeed;
          break;
        case PlayerStates.leftRunShoot:
          speedX = -horizontalSpeed;
          break;
        case PlayerStates.rightDown:
          speedX = horizontalSpeed;
          break;
        case PlayerStates.leftDown:
          speedX = -horizontalSpeed;
          break;
        case PlayerStates.rightUp:
          speedX = horizontalSpeed;
          break;
        case PlayerStates.leftUp:
          speedX = -horizontalSpeed;
          break;
        case PlayerStates.rightIdle:
          speedX = 0;
          break;
        case PlayerStates.leftIdle:
          speedX = 0;
          break;
        case PlayerStates.rightStraightDown:
          speedX = 0;
          break;
        case PlayerStates.leftStraightDown:
          speedX = 0;
          break;
        case PlayerStates.rightStraightUp:
          speedX = 0;
          break;
        case PlayerStates.leftStraightUp:
          speedX = 0;
          break;
        case PlayerStates.rightJump:
          speedX = horizontalSpeed;
          break;
        case PlayerStates.leftJump:
          speedX = -horizontalSpeed;
          break;
        case PlayerStates.leftDownJump:
          speedX = -horizontalSpeed;
          break;
        case PlayerStates.rightDownJump:
          speedX = horizontalSpeed;
          break;
        case PlayerStates.rightUpJump:
          speedX = horizontalSpeed;
          break;
        case PlayerStates.leftUpJump:
          speedX = -horizontalSpeed;
          break;
        case PlayerStates.waterRightShoot:
          speedX = horizontalSpeed;
          break;
        case PlayerStates.waterLeftShoot:
          speedX = -horizontalSpeed;
          break;
        case PlayerStates.waterRightUp:
          speedX = horizontalSpeed;
          break;
        case PlayerStates.waterLeftUp:
          speedX = -horizontalSpeed;
          break;
        case PlayerStates.waterRightIdle:
          speedX = 0;
          break;
        case PlayerStates.waterLeftIdle:
          speedX = 0;
          break;
        case PlayerStates.rightUnderWater:
          speedX = 0;
          break;
        case PlayerStates.leftUnderWater:
          speedX = 0;
          break;
        case PlayerStates.waterLeftStraightUp:
          speedX = 0;
          break;
        case PlayerStates.waterRightStraightUp:
          speedX = 0;
          break;
        case PlayerStates.rightStraightUpJump:
          speedX = 0;
          break;
        case PlayerStates.leftStraightUpJump:
          speedX = 0;
          break;
        case PlayerStates.dieRight:
          speedX = 0;
          speedY = 0;
          break;
        case PlayerStates.dieLeft:
          speedX = 0;
          speedY = 0;
          break;
        default:
          break;
      }
      if (jumping) {
        speedY = jumpUp ? -verticalSpeed : verticalSpeed;
      }
      if (jumping && position.y < maximumHeight) {
        jumpUp = false;
        maximumHeight = 0;
      }

      if (current != null) {
        playerInfoEvents.broadcast(PlayerInfoArgs(position, current!));
      }
    } else {
      speedY = verticalSpeed;
      speedX = 0;
    }
    position
        .add(Vector2(dead ? 0 : speedX, adjustVerticalSpeed ? speedY : 0) * dt);

    super.update(dt);
  }

  @override
  Future<void>? onLoad() async {
    var textureSize = Vector2(cellWidth, cellHeight);
    final rightRunShoot = await gameRef.loadSpriteAnimation(
      path,
      SpriteAnimationData.sequenced(
        amount: 3,
        textureSize: textureSize,
        texturePosition: Vector2(0, 0),
        stepTime: stepTimeFast15,
      ),
    );

    final leftRunShoot = await gameRef.loadSpriteAnimation(
      path,
      SpriteAnimationData.sequenced(
        amount: 3,
        textureSize: textureSize,
        texturePosition: Vector2(0, cellHeight),
        stepTime: stepTimeFast15,
      ),
    );

    final rightStraightUp = await gameRef.loadSpriteAnimation(
      path,
      SpriteAnimationData.sequenced(
        amount: 1,
        textureSize: textureSize,
        texturePosition: Vector2(0, cellHeight * 2),
        stepTime: stepTimeSlow100,
      ),
    );

    final leftStraightUp = await gameRef.loadSpriteAnimation(
      path,
      SpriteAnimationData.sequenced(
        amount: 1,
        textureSize: textureSize,
        texturePosition: Vector2(0, cellHeight * 3),
        stepTime: stepTimeSlow100,
      ),
    );

    final rightJump = await gameRef.loadSpriteAnimation(
      path,
      SpriteAnimationData.sequenced(
        amount: 4,
        textureSize: textureSize,
        texturePosition: Vector2(0, cellHeight * 6),
        stepTime: stepTimeFast15,
      ),
    );

    final leftJump = await gameRef.loadSpriteAnimation(
      path,
      SpriteAnimationData.sequenced(
        amount: 4,
        textureSize: textureSize,
        texturePosition: Vector2(0, cellHeight * 7),
        stepTime: stepTimeFast15,
      ),
    );

    final rightIdle = await gameRef.loadSpriteAnimation(
      path,
      SpriteAnimationData.sequenced(
        amount: 1,
        textureSize: textureSize,
        texturePosition: Vector2(0, cellHeight * 8),
        stepTime: stepTimeSlow100,
      ),
    );

    final leftIdle = await gameRef.loadSpriteAnimation(
      path,
      SpriteAnimationData.sequenced(
        amount: 1,
        textureSize: textureSize,
        texturePosition: Vector2(0, cellHeight * 9),
        stepTime: stepTimeSlow100,
      ),
    );

    final rightUp = await gameRef.loadSpriteAnimation(
      path,
      SpriteAnimationData.sequenced(
        amount: 3,
        textureSize: textureSize,
        texturePosition: Vector2(0, cellHeight * 10),
        stepTime: stepTimeFast15,
      ),
    );

    final leftUp = await gameRef.loadSpriteAnimation(
      path,
      SpriteAnimationData.sequenced(
        amount: 3,
        textureSize: textureSize,
        texturePosition: Vector2(0, cellHeight * 11),
        stepTime: stepTimeFast15,
      ),
    );

    final rightDown = await gameRef.loadSpriteAnimation(
      path,
      SpriteAnimationData.sequenced(
        amount: 3,
        textureSize: textureSize,
        texturePosition: Vector2(0, cellHeight * 12),
        stepTime: stepTimeFast15,
      ),
    );

    final leftDown = await gameRef.loadSpriteAnimation(
      path,
      SpriteAnimationData.sequenced(
        amount: 3,
        textureSize: textureSize,
        texturePosition: Vector2(0, cellHeight * 13),
        stepTime: stepTimeFast15,
      ),
    );

    final leftStraightDown = await gameRef.loadSpriteAnimation(
      path,
      SpriteAnimationData.sequenced(
        amount: 1,
        textureSize: textureSize,
        texturePosition: Vector2(0, cellHeight * 14),
        stepTime: stepTimeSlow100,
      ),
    );

    final rightStraightDown = await gameRef.loadSpriteAnimation(
      path,
      SpriteAnimationData.sequenced(
        amount: 1,
        textureSize: textureSize,
        texturePosition: Vector2(0, cellHeight * 15),
        stepTime: stepTimeSlow100,
      ),
    );

    final underWater = await gameRef.loadSpriteAnimation(
      path,
      SpriteAnimationData.sequenced(
        amount: 2,
        textureSize: textureSize,
        texturePosition: Vector2(0, cellHeight * 16),
        stepTime: stepTimeSlow30,
      ),
    );

    final waterRightShoot = await gameRef.loadSpriteAnimation(
      path,
      SpriteAnimationData.sequenced(
        amount: 1,
        textureSize: textureSize,
        texturePosition: Vector2(0, cellHeight * 19),
        stepTime: stepTimeSlow100,
      ),
    );

    final waterLeftShoot = await gameRef.loadSpriteAnimation(
      path,
      SpriteAnimationData.sequenced(
        amount: 1,
        textureSize: textureSize,
        texturePosition: Vector2(0, cellHeight * 20),
        stepTime: stepTimeSlow100,
      ),
    );

    final waterRightUp = await gameRef.loadSpriteAnimation(
      path,
      SpriteAnimationData.sequenced(
        amount: 1,
        textureSize: textureSize,
        texturePosition: Vector2(0, cellHeight * 21),
        stepTime: stepTimeSlow30,
      ),
    );

    final waterLeftUp = await gameRef.loadSpriteAnimation(
      path,
      SpriteAnimationData.sequenced(
        amount: 1,
        textureSize: textureSize,
        texturePosition: Vector2(0, cellHeight * 22),
        stepTime: stepTimeSlow30,
      ),
    );

    final waterRightStraightUp = await gameRef.loadSpriteAnimation(
      path,
      SpriteAnimationData.sequenced(
        amount: 2,
        textureSize: textureSize,
        texturePosition: Vector2(0, cellHeight * 23),
        stepTime: stepTimeSlow30,
      ),
    );

    final waterLeftStraightUp = await gameRef.loadSpriteAnimation(
      path,
      SpriteAnimationData.sequenced(
        amount: 2,
        textureSize: textureSize,
        texturePosition: Vector2(0, cellHeight * 24),
        stepTime: stepTimeSlow30,
      ),
    );

    final dieRight = await gameRef.loadSpriteAnimation(
      path,
      SpriteAnimationData.sequenced(
        amount: 5,
        textureSize: textureSize,
        texturePosition: Vector2(0, cellHeight * 25),
        stepTime: stepTimeFast15,
        loop: false,
      ),
    );

    final dieLeft = await gameRef.loadSpriteAnimation(
      path,
      SpriteAnimationData.sequenced(
        amount: 5,
        textureSize: textureSize,
        texturePosition: Vector2(0, cellHeight * 26),
        stepTime: stepTimeFast15,
        loop: false,
      ),
    );

    animations = {
      PlayerStates.rightRunShoot: rightRunShoot,
      PlayerStates.leftRunShoot: leftRunShoot,
      PlayerStates.rightStraightUp: rightStraightUp,
      PlayerStates.leftStraightUp: leftStraightUp,
      PlayerStates.rightStraightDown: rightStraightDown,
      PlayerStates.leftStraightDown: leftStraightDown,
      PlayerStates.rightJump: rightJump,
      PlayerStates.leftJump: leftJump,
      PlayerStates.rightUpJump: rightJump,
      PlayerStates.leftUpJump: leftJump,
      PlayerStates.rightStraightUpJump: rightJump,
      PlayerStates.leftStraightUpJump: leftJump,
      PlayerStates.rightStraightUpJumpNoKey: rightJump,
      PlayerStates.leftStraightUpJumpNoKey: leftJump,
      PlayerStates.rightStraightDownJump: rightJump,
      PlayerStates.leftStraightDownJump: leftJump,
      PlayerStates.rightIdle: rightIdle,
      PlayerStates.leftIdle: leftIdle,
      PlayerStates.rightUp: rightUp,
      PlayerStates.leftUp: leftUp,
      PlayerStates.rightDown: rightDown,
      PlayerStates.leftDown: leftDown,
      PlayerStates.rightDownJump: rightJump,
      PlayerStates.leftDownJump: leftJump,
      PlayerStates.waterRightShoot: waterRightShoot,
      PlayerStates.waterLeftShoot: waterLeftShoot,
      PlayerStates.rightUnderWater: underWater,
      PlayerStates.leftUnderWater: underWater,
      PlayerStates.waterRightStraightUp: waterRightStraightUp,
      PlayerStates.waterLeftStraightUp: waterLeftStraightUp,
      PlayerStates.waterRightIdle: waterRightShoot,
      PlayerStates.waterLeftIdle: waterLeftShoot,
      PlayerStates.waterLeftUp: waterLeftUp,
      PlayerStates.waterRightUp: waterRightUp,
      PlayerStates.dieRight: dieRight,
      PlayerStates.dieLeft: dieLeft,
    };
    current = PlayerStates.rightIdle;
    var hitBox = hitBoxes[current]!;
    add(RectangleHitbox(position: hitBox[0], size: hitBox[1]));
    add(WallSensor(position: Vector2(width / 2, height), size: Vector2(2, 2))
      ..paint = Paint()
      ..setColor(Colors.transparent));
    return super.onLoad();
  }

  void die() {
    if (!dead) {
      weaponTypeEvents.broadcast(WeaponTypeArgs(WeaponType.rifle));
      current = facingRight ? PlayerStates.dieLeft : PlayerStates.dieRight;
      dead = true;
      Timer(Duration(milliseconds: (30 * stepTimeFast15 * 1000).toInt()), () {
        spawnEvents.broadcast();
        removeFromParent();
      });
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    var hitBox = hitBoxes[current!];

    if (other is ContraScreenHitbox && !dead) {
      if (!dead && position.x + hitBox![0].x < gameRef.camera.position.x) {
        position.x = gameRef.camera.position.x - hitBox[0].x;
      }
      if (position.y + height > other.height) {
        die();
        adjustVerticalSpeed = false;
      }
    }

    if (other is Wall &&
        other.type == WallType.fortress &&
        !dead &&
        position.x + hitBox![0].x + hitBox[1].x > other.position.x) {
      position.x = other.position.x - hitBox[0].x - hitBox[1].x;
    }
  }
}
