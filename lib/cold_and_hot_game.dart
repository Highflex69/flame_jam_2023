import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/experimental.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flame_jam_2023/components/door.dart';
import 'package:flame_jam_2023/components/hazard.dart';
import 'package:flame_jam_2023/components/player.dart';
import 'package:flame_jam_2023/components/winning_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:leap/leap.dart';

class ColdAndHotGame extends LeapGame
    with TapCallbacks, HasKeyboardHandlerComponents {
  Player? player;
  late final ThreeButtonInput input;
  late final Map<String, TiledObjectHandler> tiledObjectHandlers;
  late final Map<String, GroundTileHandler> groundTileHandlers;
  AudioPlayer? backgroundAudioPlayer;

  ColdAndHotGame({required super.tileSize});

  static const _levels = [
    'map1.tmx',
    'map2.tmx',
    'map3.tmx',
    'winning.tmx',
  ];

  var _currentLevel = 'map1.tmx';
  bool isGameOver = false;

  Future<void> _loadLevel() async {
    if (_currentLevel != "winning.tmx") {
      return loadWorldAndMap(
        tiledMapPath: _currentLevel,
        tiledObjectHandlers: tiledObjectHandlers,
        groundTileHandlers: groundTileHandlers,
      );
    } else {
      isGameOver = true;
      world.add(WinningScreen());
    }
  }

  @override
  void onDispose() {
    FlameAudio.bgm.dispose();
    backgroundAudioPlayer?.dispose();
    super.onDispose();
  }

  @override
  Future<void> onLoad() async {
    FlameAudio.bgm.initialize();
    tiledObjectHandlers = {
      'Hazard': HazardFactory(),
      'Door': DoorFactory(),
    };

    groundTileHandlers = {
      'OneWayTopPlatform': OneWayTopPlatformHandler(),
    };
    // Default the camera size to the bounds of the Tiled map.
    camera = CameraComponent.withFixedResolution(
      world: world,
      width: tileSize * 32,
      height: tileSize * 16,
    );
    input = ThreeButtonInput(
      keyboardInput: ThreeButtonKeyboardInput(
        leftKeys: {PhysicalKeyboardKey.keyA},
        centerKeys: {PhysicalKeyboardKey.keyW},
        rightKeys: {PhysicalKeyboardKey.keyD},
      ),
    );
    add(input);

    await _loadLevel();
    // Don't let the camera move outside the bounds of the map, inset
    // by half the viewport size to the edge of the camera if flush with the
    // edge of the map.
    final inset = camera.viewport.virtualSize;

    camera.setBounds(
      Rectangle.fromLTWH(
        inset.x / 2,
        inset.y / 2,
        leapMap.width - inset.x,
        leapMap.height - inset.y,
      ),
    );

    player = Player();
    world.add(player!);
    camera.follow(player!);
    await super.onLoad();
  }

  @override
  void onMapUnload(LeapMap map) {
    player?.removeFromParent();
  }

  @override
  void onMapLoaded(LeapMap map) {
    if (player != null) {
      player = Player();
      world.add(player!);
      camera.follow(player!);
    }
  }

  Future<void> levelCleared() async {
    final i = _levels.indexOf(_currentLevel);
    _currentLevel = _levels[(i + 1) % _levels.length];
    await _loadLevel();
  }

  @override
  KeyEventResult onKeyEvent(
      RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    super.onKeyEvent(event, keysPressed);
    if (backgroundAudioPlayer == null && !isGameOver) {
      initAudioPlayer();
    }
    return KeyEventResult.ignored;
  }

  Future<void> initAudioPlayer() async {
    backgroundAudioPlayer ??= await FlameAudio.loop('background.mp3');
  }
}
