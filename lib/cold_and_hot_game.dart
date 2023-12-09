import 'package:flame/camera.dart';
import 'package:flame/events.dart';
import 'package:flame/experimental.dart';
import 'package:flame_jam_2023/components/door.dart';
import 'package:flame_jam_2023/components/info_text.dart';
import 'package:flame_jam_2023/components/player.dart';
import 'package:flutter/services.dart';
import 'package:leap/leap.dart';

class ColdAndHotGame extends LeapGame
    with TapCallbacks, HasKeyboardHandlerComponents {
  final Player player = Player();
  late final ThreeButtonInput input;
  late final Map<String, TiledObjectHandler> tiledObjectHandlers;
  late final Map<String, GroundTileHandler> groundTileHandlers;

  ColdAndHotGame({required super.tileSize});

  static const _levels = [
    'map_everything.tmx',
  ];

  var _currentLevel = 'map_everything.tmx';

  Future<void> _loadLevel() {
    return loadWorldAndMap(
      tiledMapPath: _currentLevel,
      tiledObjectHandlers: tiledObjectHandlers,
      groundTileHandlers: groundTileHandlers,
    );
  }

  @override
  Future<void> onLoad() async {
    groundTileHandlers = {
      'OneWayTopPlatform': OneWayTopPlatformHandler(),
    };
    // Default the camera size to the bounds of the Tiled map.
    camera = CameraComponent.withFixedResolution(
      world: world,
      width: tileSize * 32,
      height: tileSize * 16,
    );

    tiledObjectHandlers = {
      'Door': DoorFactory(),
      'InfoText': InfoTextFactory(),
    };

    input = ThreeButtonInput(
      keyboardInput: ThreeButtonKeyboardInput(
        leftKeys: {PhysicalKeyboardKey.keyA},
        centerKeys: {PhysicalKeyboardKey.keyW},
        rightKeys: {PhysicalKeyboardKey.keyD},
      ),
    );
    add(input);

    await _loadLevel();
    world.add(player);

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

    world.add(player);
    camera.follow(player);
  }

  @override
  void onMapUnload(LeapMap map) {
    player.removeFromParent();
  }

  Future<void> levelCleared() async {
    //final i = _levels.indexOf(_currentLevel);
    //_currentLevel = _levels[(i + 1) % _levels.length];

    await _loadLevel();
  }

  Future<void> goToLevel(String mapName) async {
    _currentLevel = mapName;
    await _loadLevel();
  }
}
