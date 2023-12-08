import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flame/flame.dart';
import 'package:flame_jam_2023/cold_and_hot_game.dart';
import 'package:flutter/services.dart';
import 'package:leap/leap.dart';

enum _AnimationState { idle }

class Player extends JumperCharacter<ColdAndHotGame> {
  Player({super.health = initialHealth}) : super(removeOnDeath: false) {
    solidTags.add(CommonTags.ground);
  }

  static const initialHealth = 1;

  late final Vector2 _spawn;
  late final ThreeButtonInput _input;
  double timeHoldingJump = 0;

  double deadTime = 0;

  /// Render on top of the map tiles.
  @override
  int get priority => 10;

  @override
  Future<void> onLoad() async {
    _input = game.input;
    _spawn = map.playerSpawn;

    characterAnimation = PlayerSpriteAnimation();

    // Size controls player hitbox, which should be slightly smaller than
    // visual size of the sprite.
    size = Vector2(10, 24);

    resetPosition();

    walkSpeed = map.tileSize * 7;
    minJumpImpulse = world.gravity * 0.6;
  }

  @override
  void update(double dt) {
    super.update(dt);

    final wasAlive = isAlive;
    final wasJumping = jumping;

    updateHandleInput(dt);

    //updateCollisionInteractions(dt);

    if (isDead) {
      deadTime += dt;
      walking = false;
    }

    if (world.isOutside(this) || (isDead && deadTime > 3)) {
      health = initialHealth;
      deadTime = 0;
      resetPosition();
    }

    if (wasAlive && !isAlive) {
      //FlameAudio.play('die.wav');
    }
    if (!wasJumping && jumping) {
      //FlameAudio.play('jump.wav');
    }
  }

  void resetPosition() {
    x = _spawn.x;
    y = _spawn.y;
    velocity.x = 0;
    velocity.y = 0;
    airXVelocity = 0;
    faceLeft = false;
    jumping = false;

    //FlameAudio.play('spawn.wav');
  }

  void updateHandleInput(double dt) {
    if (isAlive) {
      // Keep jumping if started.
      if (jumping &&
          _input.isPressed &&
          timeHoldingJump < maxJumpHoldTime &&
          // hitting a ceiling should behave the same
          // as letting go of the jump button
          !collisionInfo.up) {
        jumping = true;
        timeHoldingJump += dt;
      } else {
        jumping = false;
        timeHoldingJump = 0;
      }
    }

    if (isAlive) {
      // Keep jumping if started.
      if (jumping &&
          _input.isPressed &&
          timeHoldingJump < maxJumpHoldTime &&
          // hitting a ceiling should behave the same
          // as letting go of the jump button
          !collisionInfo.up) {
        jumping = true;
        timeHoldingJump += dt;
      } else {
        jumping = false;
        timeHoldingJump = 0;
      }
    }

    final ladderCollision =
        collisionInfo.allCollisions.whereType<Ladder>().firstOrNull;
    final onLadderStatus = getStatus<OnLadderStatus>();
    if (_input.justPressed &&
        _input.isPressedCenter &&
        ladderCollision != null &&
        onLadderStatus == null) {
      final status = OnLadderStatus(ladderCollision);
      add(status);
      walking = false;
      airXVelocity = 0;
      if (isOnGround) {
        status.movement = LadderMovement.down;
      } else {
        status.movement = LadderMovement.up;
      }
    } else if (_input.justPressed && onLadderStatus != null) {
      if (_input.isPressedCenter) {
        if (onLadderStatus.movement != LadderMovement.stopped) {
          onLadderStatus.movement = LadderMovement.stopped;
        } else if (onLadderStatus.prevDirection == LadderMovement.up) {
          onLadderStatus.movement = LadderMovement.down;
        } else {
          onLadderStatus.movement = LadderMovement.up;
        }
      } else {
        // JumperBehavior will handle applying the jump and exiting the ladder
        jumping = true;
        airXVelocity = walkSpeed;
        walking = true;
        // Make sure the player exits the ladder facing the direction jumped
        faceLeft = _input.isPressedLeft;
      }
    } else if (_input.justPressed && _input.isPressedLeft) {
      // Tapped left.
      if (walking) {
        if (faceLeft) {
          // Already moving left.
          if (isOnGround) {
            jumping = true;
          }
        } else {
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
        if (!faceLeft) {
          // Already moving right.
          if (isOnGround) {
            jumping = true;
          }
        } else {
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
}

class PlayerSpriteAnimation extends CharacterAnimation<_AnimationState, Player>
    with HasGameRef<LeapGame> {
  PlayerSpriteAnimation() : super(scale: Vector2.all(2));

  @override
  Future<dynamic> onLoad() async {
    final spriteSheet = await gameRef.images.load('player_spritesheet.png');

    animations = {
      _AnimationState.idle: SpriteAnimation.fromFrameData(
          spriteSheet,
          SpriteAnimationData.sequenced(
            amount: 2,
            stepTime: 0.4,
            textureSize: Vector2.all(16),
            amountPerRow: 2,
          ))
    };
    current = _AnimationState.idle;
  }
}
