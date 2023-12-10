import 'package:flame/components.dart';
import 'package:flame_jam_2023/cold_and_hot_game.dart';
import 'package:leap/leap.dart';
import 'package:tiled/tiled.dart';

class Door extends PhysicalEntity<ColdAndHotGame> {
  Door(TiledObject object, ObjectGroup layer)
      : super(
          position: Vector2(object.x, object.y),
          size: Vector2(object.width, object.height),
          static: true,
        );

  void levelCleared() {
    gameRef.levelCleared();
  }
}

class DoorFactory implements TiledObjectHandler {
  @override
  void handleObject(TiledObject object, Layer layer, LeapMap map) {
    final component = Door(object, layer as ObjectGroup);
    map.add(component);
  }
}
