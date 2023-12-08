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
        ) {
    destinationMap = object.properties.getValue<String>('DestinationMap');
    final destinationObjectId =
        object.properties.getValue<int>('DestinationObject');
    if (destinationObjectId != null) {
      destinationObject =
          layer.objects.firstWhere((obj) => obj.id == destinationObjectId);
    }
  }

  late final String? destinationMap;
  late final TiledObject? destinationObject;

  void enter(PhysicalEntity other) {
    if (destinationMap != null) {
      game.goToLevel(destinationMap!);
    } else if (destinationObject != null) {
      other.x = destinationObject!.x;
      other.y = destinationObject!.y;
    }
  }
}

class DoorFactory implements TiledObjectHandler {
  @override
  void handleObject(TiledObject object, Layer layer, LeapMap map) {
    final component = Door(object, layer as ObjectGroup);
    map.add(component);
  }
}
