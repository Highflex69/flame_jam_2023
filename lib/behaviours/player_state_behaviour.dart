import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:flame_jam_2023/components/player.dart';

enum IceCubeState { idle, running, jump, melting }

class PlayerStateBehavior extends Behavior<Player> {
  IceCubeState? _state;

  late final Map<IceCubeState, PositionComponent> _stateMap;

  IceCubeState get state => _state ?? IceCubeState.idle;

  static const _needResetStates = {
    IceCubeState.jump,
  };

  final double animationSize = 64;

  void updateSpritePaintColor(Color color) {
    for (final component in _stateMap.values) {
      if (component is HasPaint) {
        (component as HasPaint).paint.color = color;
      }
    }
  }

  void fadeOut({VoidCallback? onComplete}) {
    final component = _stateMap[state];
    if (component != null && component is HasPaint) {
      component.add(
        OpacityEffect.fadeOut(
          EffectController(duration: .5),
          onComplete: onComplete,
        ),
      );
    }
  }

  void fadeIn({VoidCallback? onComplete}) {
    final component = _stateMap[state];
    if (component != null && component is HasPaint) {
      component.add(
        OpacityEffect.fadeIn(
          EffectController(duration: .5, startDelay: .8),
          onComplete: onComplete,
        ),
      );
    }
  }

  set state(IceCubeState state) {
    if (state != _state) {
      final current = _stateMap[_state];

      if (current != null) {
        current.removeFromParent();

        if (_needResetStates.contains(_state)) {
          if (current is SpriteAnimationComponent) {
            current.animationTicker?.reset();
          }
        }
      }

      final replacement = _stateMap[state];
      if (replacement != null) {
        parent.add(replacement);
      }
      _state = state;
    }
  }

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();

    final [
      idleAnimation,
      runningAnimation,
      jumpAnimation,
    ] = await Future.wait(
      [
        parent.gameRef.loadSpriteAnimation(
          'player.png',
          SpriteAnimationData.range(
            amount: 6,
            stepTimes: [0.2, 0.2, 0.2],
            textureSize: Vector2.all(animationSize),
            start: 0,
            end: 2,
          ),
        ),
        parent.gameRef.loadSpriteAnimation(
          'player.png',
          SpriteAnimationData.range(
            amount: 6,
            stepTimes: [0.2, 0.2],
            textureSize: Vector2.all(animationSize),
            start: 3,
            end: 4,
          ),
        ),
        parent.gameRef.loadSpriteAnimation(
          'player.png',
          SpriteAnimationData.range(
            amount: 6,
            stepTimes: [0.2],
            textureSize: Vector2.all(animationSize),
            start: 5,
            end: 5,
          ),
        ),
      ],
    );

    final paint = Paint()..isAntiAlias = false;

    _stateMap = {
      IceCubeState.idle: SpriteAnimationComponent(
        animation: idleAnimation,
        paint: paint,
      ),
      IceCubeState.running: SpriteAnimationComponent(
        animation: runningAnimation,
        paint: paint,
      ),
      IceCubeState.jump: SpriteAnimationComponent(
        animation: jumpAnimation,
        paint: paint,
      ),
    };

    state = IceCubeState.idle;
  }
}
