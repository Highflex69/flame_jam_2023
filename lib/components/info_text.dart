import 'package:flame/components.dart';
import 'package:flame_jam_2023/cold_and_hot_game.dart';
import 'package:leap/leap.dart';
import 'package:tiled/tiled.dart';

class InfoText extends PhysicalEntity<ColdAndHotGame> {
  InfoText(TiledObject object)
      : super(
          position: Vector2(object.x, object.y),
          size: Vector2(object.width, object.height),
          static: true,
        );
}

class InfoTextFactory implements TiledObjectHandler {
  @override
  void handleObject(TiledObject object, Layer layer, LeapMap map) {
    final component = InfoText(object);
    map.add(component);
  }
}
