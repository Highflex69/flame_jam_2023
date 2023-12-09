import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flame_jam_2023/behaviours/controller_behaviour.dart';
import 'package:flame_jam_2023/behaviours/player_state_behaviour.dart';
import 'package:flame_jam_2023/cold_and_hot_game.dart';
import 'package:flame_jam_2023/components/door.dart';
import 'package:leap/leap.dart';

const double defaultCharacterSize = 16;

class Player extends JumperCharacter<ColdAndHotGame> {
  Player({super.health = initialHealth}) : super(removeOnDeath: false) {
    solidTags.add(CommonTags.ground);
  }

  static const initialHealth = 100;
  static const jumpImpulse = .6;

  late final Vector2 _spawn;
  late final double initMaxJumpHoldTime;

  //late final ThreeButtonInput _input;
  late final PlayerStateBehavior stateBehavior =
      findBehavior<PlayerStateBehavior>();
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
    //_input = game.input;
    _spawn = map.playerSpawn;
    initMaxJumpHoldTime = maxJumpHoldTime;
    //characterAnimation = PlayerSpriteAnimation();
    // Size controls player hitbox, which should be slightly smaller than
    // visual size of the sprite.
    size = Vector2.all(56);
    walkSpeed = map.tileSize * 7;
    minJumpImpulse = world.gravity * jumpImpulse;
    add(PlayerControllerBehavior());
    add(PlayerStateBehavior());
    resetPosition();
  }

  @override
  set walking(bool value) {
    if (!super.walking && value) {
      setRunningState();
    } else if (super.walking && !value) {
      setIdleState();
    }

    super.walking = value;
  }

  @override
  void update(double dt) {
    super.update(dt);

    final wasAlive = isAlive;

    if (_jumpTimer >= 0) {
      _jumpTimer -= dt;

      if (_jumpTimer <= 0) {
        jumping = false;
      }
    }

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
  }

  void updateCollisionInteractions(double dt) {
    if (isDead) {
      return;
    }

    for (final other in collisionInfo.allCollisions) {
      if (stateBehavior.state != IceCubeState.melting &&
          other.tags.contains("Hazard")) {
        if (damageTimer < maxDamageTimer) {
          damageTimer += dt;
          meltPlayer();
        } else {
          //reset timer because player is out of harm
          damageTimer = 0;
          setIdleState();
        }
      } else if (other is Door) {
        other.enter(this);
      } else {
        setIdleState();
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
    //characterAnimation!.size = Vector2.all(defaultCharacterSize.toDouble());
    size = Vector2.all(56);
    //FlameAudio.play('spawn.wav');
  }

  void meltPlayer() {
    if (characterAnimation != null) {
      // dmg = 10hp
      const damage = 10; //collisionInfo.allCollisions.first.hazardDamage;
      health -= damage;
      setMeltingState();
      const reduction = defaultCharacterSize * 0.1;

      if (characterAnimation!.size.y - reduction > 0) {
        characterAnimation!.size -= Vector2.all(reduction);
        size -= (size * 0.1);
        maxJumpHoldTime += maxJumpHoldTime * 0.1;
      }
    }
  }

  jumpEffects() {
    FlameAudio.play('jump.wav');
    stateBehavior.state = IceCubeState.jump;
  }

  void setRunningState() {
    final behavior = stateBehavior;
    if (behavior.state != IceCubeState.running) {
      const newRunState = IceCubeState.running;
      if (behavior.state != newRunState) {
        behavior.state = newRunState;
      }
    }
  }

  void setIdleState() {
    stateBehavior.state = IceCubeState.idle;
  }

  void setMeltingState() {
    stateBehavior.state = IceCubeState.melting;
  }

/*void gainSize() {
    if (characterAnimation != null) {
      // dmg = 10hp
      final damage = collisionInfo.downCollision!.hazardDamage;
      health -= damage;
      status = _Status.freezing;
      final growth = defaultCharacterSize * (damage / 100);

      if (characterAnimation!.size.y + growth < defaultCharacterSize * 2) {
        characterAnimation!.size += Vector2.all(growth);
        maxJumpHoldTime += maxJumpHoldTime * 0.2;
      }
    }
  }*/
}

/*class PlayerSpriteAnimation extends CharacterAnimation<_AnimationState, Player>
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
          textureSize: Vector2.all(defaultCharacterSize.toDouble()),
          amountPerRow: 2,
        ),
      )
    };
    current = _AnimationState.idle;
  }
}*/
