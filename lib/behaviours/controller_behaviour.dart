import 'dart:async';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:flame_jam_2023/components/player.dart';

class PlayerControllerBehavior extends Behavior<Player> {
  double _jumpTimer = 0;

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();

    parent.gameRef.addInputListener(_handleInput);
  }

  @override
  void onRemove() {
    super.onRemove();

    parent.gameRef.removeInputListener(_handleInput);
  }

  void _handleInput() {
    if (parent.isDead) {
      return;
    }

    // Do nothing when there is a jump cool down
    if (_jumpTimer >= 0) {
      return;
    }

    // If is walking, jump
    if (parent.walking && parent.isOnGround) {
      parent
        ..jumpEffects()
        ..jumping = true;
      _jumpTimer = 0.04;
      return;
    }
  }

  void _handleJumpInput() {
    if (parent.isDead) {
      return;
    }

    // If is no walking, start walking
    if (!parent.walking) {
      parent.walking = true;
      return;
    }

    // If is walking, jump
    if (parent.walking && parent.isOnGround) {
      parent
        ..jumpEffects()
        ..jumping = true;
      _jumpTimer = 0.04;
      return;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (parent.isDead && parent.jumping) {
      parent.jumping = false;
    }

    if (parent.isDead) {
      return;
    }

    if (_jumpTimer >= 0) {
      _jumpTimer -= dt;

      if (_jumpTimer <= 0) {
        parent.jumping = false;
      }
    }

    if (_jumpTimer <= 0 && parent.isOnGround && parent.walking) {
      parent.setRunningState();
    }
  }
}
