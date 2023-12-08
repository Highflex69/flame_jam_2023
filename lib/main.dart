void main() {
  runApp(
    GameWidget(game: MyGame()),
  );
}

class MyGame extends FlameGame {
  @override
  Future<void> onLoad() async {
  }
}