import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flame_jam_2023/cold_and_hot_game.dart';
import 'package:flame_jam_2023/components/door.dart';
import 'package:flame_jam_2023/components/hazard.dart';
import 'package:leap/leap.dart';

const double defaultCharacterSizeX = 384 / 6;
const double defaultCharacterSizeY = 55;
const double scaledCharacterSizeX = defaultCharacterSizeX * 0.5;
const double scaledCharacterSizeY = defaultCharacterSizeY * 0.5;

class Player extends JumperCharacter<ColdAndHotGame> {
  Player({super.health = initialHealth}) : super(removeOnDeath: false) {
    solidTags.add(CommonTags.ground);
  }

  static const initialHealth = 100;
  static const jumpImpulse = .6;

  late final Vector2 _spawn;
  late final ThreeButtonInput _input;
  late final double initMaxJumpHoldTime;

  var maxDamageTimer = 0.1;
  double damageTimer = 0;
  double timeHoldingJump = 0;

  double deadTime = 0;

  /// Render on top of the map tiles.
  @override
  int get priority => 10;

  /// test setup:
  double _jumpTimer = 0;
  double _currentJumpTimer = 0.04;
  final _defaultJumpTimer = 0.04;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _input = game.input;
    _spawn = map.playerSpawn;
    initMaxJumpHoldTime = maxJumpHoldTime;
    walkSpeed = map.tileSize * 7;
    minJumpImpulse = world.gravity * jumpImpulse;
    resetPosition();
  }

  @override
  void update(double dt) {
    super.update(dt);

    final wasAlive = isAlive;

    if (isDead && jumping) {
      jumping = false;
    }
    if (_jumpTimer >= 0) {
      _jumpTimer -= dt;

      if (_jumpTimer <= 0) {
        jumping = false;
      }
    }

    updateHandleInput(dt);
    updateCollisionInteractions(dt);

    if (isDead) {
      deadTime += dt;
      walking = false;
      jumping = false;
    }

    if (world.isOutside(this) || (isDead && deadTime > 3)) {
      health = initialHealth;
      deadTime = 0;
      resetPosition();
    }

    if (wasAlive && !isAlive) {
      FlameAudio.play('death.wav');
    }
  }

  void updateCollisionInteractions(double dt) {
    if (isDead) {
      return;
    }

    for (final other in collisionInfo.allCollisions) {
      final isHazard =
          collisionInfo.downCollision?.tags.contains("Hazard") ?? false;
      if (other is Hazard || isHazard) {
        if (damageTimer >= 0) {
          damageTimer -= dt;

          if (damageTimer <= 0) {
            meltPlayer();
          }
        }
      } else if (other is Door) {
        other.levelCleared();
      }
    }
  }

  void resetPosition() {
    x = _spawn.x;
    y = _spawn.y;
    velocity.x = 0;
    velocity.y = 0;
    airXVelocity = 0;
    jumping = false;
    _currentJumpTimer = _defaultJumpTimer;
    size = Vector2(scaledCharacterSizeX, scaledCharacterSizeX);
    characterAnimation = PlayerSpriteAnimation();
    //FlameAudio.play('spawn.wav');
  }

  void updateHandleInput(double dt) {
    if (characterAnimation!.current != _AnimationState.jump &&
        _input.isPressed &&
        _input.isPressedCenter) {
      jumpEffects(dt);
    }

    if (_input.justPressed && _input.isPressedLeft) {
      // Tapped left.
      if (walking) {
        if (!faceLeft) {
          // Moving right, stop.
          if (isOnGround) {
            walking = false;
          }
          faceLeft = true;
        }
      } else {
        // Standing still.
        walking = true;
        faceLeft = true;
        if (isOnGround) {
          airXVelocity = walkSpeed;
        }
      }
    } else if (_input.justPressed && _input.isPressedRight) {
      // Tapped right.
      if (walking) {
        if (faceLeft) {
          // Moving left, stop.
          if (isOnGround) {
            walking = false;
          }
          faceLeft = false;
        }
      } else {
        // Standing still.
        walking = true;
        faceLeft = false;
        if (isOnGround) {
          airXVelocity = walkSpeed;
        }
      }
    }
  }

  void meltPlayer() {
    // dmg = 10hp
    print("damage tick!");
    const damage = 10;
    health -= damage;
    final reduction = Vector2(
          scaledCharacterSizeX,
          scaledCharacterSizeX,
        ) *
        0.1;
    damageTimer = 0.5;
    if (characterAnimation!.size.y - reduction.y > 0) {
      characterAnimation!.size -= reduction;
      size -= reduction;
      _currentJumpTimer = _currentJumpTimer * 1.3;
      maxJumpHoldTime += maxJumpHoldTime * 0.2;
    }
  }

  jumpEffects(double dt) {
    jumping = true;
    _jumpTimer = _currentJumpTimer;
    FlameAudio.play('jump.wav');
  }
}

enum _AnimationState {
  idle,
  walk,
  jump,
}

class PlayerSpriteAnimation extends CharacterAnimation<_AnimationState, Player>
    with HasGameRef<LeapGame> {
  PlayerSpriteAnimation() : super(scale: Vector2.all(0.5));

  @override
  Future<void>? onLoad() async {
    final spritesheet = await gameRef.images.load('player.png');

    animations = {
      _AnimationState.idle: SpriteAnimation.fromFrameData(
        spritesheet,
        SpriteAnimationData.range(
          amount: 6,
          stepTimes: [0.2, 0.2, 0.2],
          textureSize: Vector2(
            defaultCharacterSizeX,
            defaultCharacterSizeY,
          ),
          start: 0,
          end: 2,
        ),
      ),
      _AnimationState.walk: SpriteAnimation.fromFrameData(
        spritesheet,
        SpriteAnimationData.range(
          amount: 6,
          stepTimes: [0.2, 0.2],
          textureSize: Vector2(
            defaultCharacterSizeX,
            defaultCharacterSizeY,
          ),
          start: 3,
          end: 4,
        ),
      ),
      _AnimationState.jump: SpriteAnimation.fromFrameData(
        spritesheet,
        SpriteAnimationData.range(
          amount: 6,
          stepTimes: [0.2],
          textureSize: Vector2(
            defaultCharacterSizeX,
            defaultCharacterSizeY,
          ),
          start: 5,
          end: 5,
        ),
      ),
    };

    current = _AnimationState.idle;

    return super.onLoad();
  }

  @override
  void update(double dt) {
    // Default to playing animations
    playing = true;

    if (character.isOnGround) {
      // On the ground.
      if (character.velocity.x.abs() > 0) {
        current = _AnimationState.walk;
      } else {
        current = _AnimationState.idle;
      }
    } else {
      if (character.velocity.y < 0) {
        current = _AnimationState.jump;
      }
    }
    super.update(dt);
  }
}
