import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flame_jam_2023/cold_and_hot_game.dart';
import 'package:flame_jam_2023/components/door.dart';
import 'package:flame_jam_2023/components/hazard.dart';
import 'package:leap/leap.dart';

const double defaultCharacterSize = 64;

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
  double timeHoldingJump = 0;
  double damageTimer = 0;

  double deadTime = 0;

  /// Render on top of the map tiles.
  @override
  int get priority => 10;

  /// test setup:
  double _jumpTimer = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _input = game.input;
    _spawn = map.playerSpawn;
    initMaxJumpHoldTime = maxJumpHoldTime;
    // Size controls player hitbox, which should be slightly smaller than
    // visual size of the sprite.
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
      if (other is Hazard) {
        meltPlayer();
      } else if (other is Door) {
        other.enter(this);
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
    size = Vector2.all(defaultCharacterSize);
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
    const damage = 10; //collisionInfo.allCollisions.first.hazardDamage;
    health -= damage;
    final reduction = Vector2.all(defaultCharacterSize * 0.1);

    if (characterAnimation!.size.y - reduction.y > 0) {
      characterAnimation!.size -= reduction;
      size -= reduction;
      maxJumpHoldTime += maxJumpHoldTime * 0.1;
    }
  }

  jumpEffects(double dt) {
    jumping = true;
    _jumpTimer = 0.04;
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
  PlayerSpriteAnimation();

  @override
  Future<void>? onLoad() async {
    final spritesheet = await gameRef.images.load('player.png');

    animations = {
      _AnimationState.idle: SpriteAnimation.fromFrameData(
        spritesheet,
        SpriteAnimationData.range(
          amount: 6,
          stepTimes: [0.2, 0.2, 0.2],
          textureSize: Vector2.all(defaultCharacterSize),
          start: 0,
          end: 2,
        ),
      ),
      _AnimationState.walk: SpriteAnimation.fromFrameData(
        spritesheet,
        SpriteAnimationData.range(
          amount: 6,
          stepTimes: [0.2, 0.2],
          textureSize: Vector2.all(defaultCharacterSize),
          start: 3,
          end: 4,
        ),
      ),
      _AnimationState.jump: SpriteAnimation.fromFrameData(
        spritesheet,
        SpriteAnimationData.range(
          amount: 6,
          stepTimes: [0.2],
          textureSize: Vector2.all(defaultCharacterSize),
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
