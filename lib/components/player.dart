import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flame_jam_2023/components/door.dart';
import 'package:flame_jam_2023/components/info_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flame/flame.dart';
import 'package:flame_jam_2023/cold_and_hot_game.dart';
import 'package:flutter/services.dart';
import 'package:leap/leap.dart';

enum _AnimationState {
  idle,
}

enum _Status {
  melting,
  idle,
  freezing,
}

const double defaultCharacterSize = 16;

class Player extends JumperCharacter<ColdAndHotGame> {
  Player({super.health = initialHealth}) : super(removeOnDeath: false) {
    solidTags.add(CommonTags.ground);
  }

  static const initialHealth = 100;
  late final Vector2 _spawn;
  late final double initMaxJumpHoldTime;
  late final ThreeButtonInput _input;
  double timeHoldingJump = 0;
  var status = _Status.idle;

  double deadTime = 0;

  /// Render on top of the map tiles.
  @override
  int get priority => 10;

  @override
  Future<void> onLoad() async {
    _input = game.input;
    _spawn = map.playerSpawn;
    initMaxJumpHoldTime = double.parse("$maxJumpHoldTime");
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
      //FlameAudio.play('die.wav');
    }
    if (!wasJumping && jumping) {
      //FlameAudio.play('jump.wav');
    }
  }

  void updateCollisionInteractions(double dt) {
    if (isDead) {
      return;
    }
    final collidingWithHazard =
        (collisionInfo.downCollision?.tags.contains('Hazard') ?? false);

    final collidingWithInfo =
        (collisionInfo.downCollision?.tags.contains('Hazard') ?? false);
    if (status != _Status.freezing && collidingWithHazard) {
      meltPlayer();
    } else if (status != _Status.idle && !collidingWithHazard) {
      status = _Status.idle;
    }

    for (final other in collisionInfo.allCollisions) {
      if (other is Door && _input.justPressed && _input.isPressedCenter) {
        other.enter(this);
      } else if (other is InfoText) {
        gainSize();
      }
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
    characterAnimation!.size = Vector2.all(defaultCharacterSize);
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
        airXVelocity = walkSpeed;
        timeHoldingJump += dt;
        //airXVelocity = walkSpeed;
      } else {
        jumping = false;
        timeHoldingJump = 0;
      }
    }
    if (_input.justPressed && _input.isPressedCenter && !jumping) {
      jumping = true;
      //airXVelocity = walkSpeed;
      walking = true;
      faceLeft = _input.isPressedLeft;
      //faceRight = _input.isPressedRight;
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
    if (characterAnimation != null) {
      // dmg = 10hp
      health -= collisionInfo.downCollision!.hazardDamage;
      status = _Status.freezing;
      const reduction = defaultCharacterSize * 0.1;

      if (characterAnimation!.size.y - reduction > 0) {
        characterAnimation!.size -= Vector2.all(reduction);
        maxJumpHoldTime -= maxJumpHoldTime * 0.2;
      }
    }
  }

  void gainSize() {
    if (characterAnimation != null) {
      // dmg = 10hp
      health -= collisionInfo.downCollision!.hazardDamage;
      status = _Status.freezing;
      const growth = defaultCharacterSize * 0.1;

      if (characterAnimation!.size.y + growth < defaultCharacterSize * 2) {
        characterAnimation!.size += Vector2.all(growth);
        maxJumpHoldTime += initMaxJumpHoldTime * 0.2;
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
            textureSize: Vector2.all(defaultCharacterSize),
            amountPerRow: 2,
          ))
    };
    current = _AnimationState.idle;
  }
}