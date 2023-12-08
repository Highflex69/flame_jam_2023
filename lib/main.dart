import 'package:flame/game.dart';
import 'package:flame_jam_2023/cold_and_hot_game.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    GameWidget(game: ColdAndHotGame(tileSize: 16/*32*/)),
  );
}
