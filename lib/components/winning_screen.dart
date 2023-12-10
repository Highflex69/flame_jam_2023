import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame_jam_2023/cold_and_hot_game.dart';

class WinningScreen extends SpriteComponent with HasGameRef<ColdAndHotGame> {
  WinningScreen();

  @override
  Future<void> onLoad() async {
    final background = await Flame.images.load("winning.jpg");
    size = gameRef.size;
    sprite = Sprite(background);
  }
}
