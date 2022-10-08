import 'dart:math';

import 'package:flame/components.dart';
import 'package:provider/provider.dart';

import 'game.dart';
import 'enemy.dart';
import 'knows_game_size.dart';

import '../models/enemy_data.dart';
import '../models/player_data.dart';

// This component class takes care of spawning new enemy components
// randomly from top of the screen. It uses the HasGameRef mixin so that
// it can add child components.
class EnemyManager extends Component
    with KnowsGameSize, HasGameRef<MoretiniInvaders> {
  // The timer which runs the enemy spawner code at regular interval of time.
  late Timer _timer;

  // Controls for how long EnemyManager should stop spawning new enemies.
  late Timer _freezeTimer;

  // Holds an object of Random class to generate random numbers.
  Random random = Random();

  EnemyManager() : super() {
    // Sets the timer to call _spawnEnemy() after every 1 second, until timer is explicitly stops.
    _timer = Timer(1, onTick: _spawnEnemy, repeat: true);

    // Sets freeze time to 2 seconds. After 2 seconds spawn timer will start again.
    _freezeTimer = Timer(2, onTick: () {
      _timer.start();
    });
  }

  // Spawns a new enemy at random position at the top of the screen.
  void _spawnEnemy() {
    Vector2 initialSize = Vector2(50, 50);

    // random.nextDouble() generates a random number between 0 and 1.
    // Multiplying it by gameRef.size.x makes sure that the value remains between 0 and width of screen.
    Vector2 position =
        Vector2(random.nextDouble() * gameRef.size.x, -initialSize[1] / 2);

    // Clamps the vector such that the enemy sprite remains within the screen.
    // Start at negative position to smoothen the sprite appearance.
    position.clamp(
      Vector2(initialSize[0] / 2, -initialSize[1] / 2),
      gameRef.size - initialSize / 2,
    );

    // Make sure that we have a valid BuildContext before using it.
    if (gameRef.buildContext != null) {
      // Get current score and figure out the max level of enemy that
      // can be spawned for this score.
      int currentScore =
          Provider.of<PlayerData>(gameRef.buildContext!, listen: false)
              .currentScore;
      int maxLevel = mapScoreToMaxEnemyLevel(currentScore);

      /// Gets a random [EnemyData] object from the list.
      final enemyData = _enemyDataList.elementAt(random.nextInt(maxLevel * 4));

      Enemy enemy = Enemy(
        sprite: Sprite(gameRef.images.fromCache(enemyData.image)),
        size: initialSize,
        position: position,
        enemyData: enemyData,
      );

      // Makes sure that the enemy sprite is centered.
      enemy.anchor = Anchor.center;

      // Add it to components list of game instance, instead of EnemyManager.
      // This ensures the collision detection working correctly.
      gameRef.add(enemy);
    }
  }

  // For a given score, this method returns a max level
  // of enemy that can be used for spawning.
  int mapScoreToMaxEnemyLevel(int score) {
    int level = 1;

    if (score > 1500) {
      level = 4;
    } else if (score > 500) {
      level = 3;
    } else if (score > 100) {
      level = 2;
    }

    return level;
  }

  @override
  void onMount() {
    super.onMount();
    // Start the timer as soon as current enemy manager get prepared
    // and added to the game instance.
    _timer.start();
  }

  @override
  void onRemove() {
    super.onRemove();
    // Stop the timer if current enemy manager is getting removed from the
    // game instance.
    _timer.stop();
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Update timers with delta time to make them tick.
    _timer.update(dt);
    _freezeTimer.update(dt);
  }

  // Stops and restarts the timer. Should be called
  // while restarting and exiting the game.
  void reset() {
    _timer.stop();
    _timer.start();
  }

  // Pauses spawn timer for 2 seconds when called.
  void freeze() {
    _timer.stop();
    _freezeTimer.stop();
    _freezeTimer.start();
  }

  /// A private list of all [EnemyData]s.
  static const List<EnemyData> _enemyDataList = [
    EnemyData(
      killPoint: 1,
      speed: 200,
      level: 1,
      hMove: false,
      image: 'enemyBlack1.png',
    ),
    EnemyData(
      killPoint: 2,
      speed: 200,
      level: 1,
      hMove: false,
      image: 'enemyBlack2.png',
    ),
    EnemyData(
      killPoint: 4,
      speed: 200,
      level: 1,
      hMove: false,
      image: 'enemyBlack3.png',
    ),
    EnemyData(
      killPoint: 4,
      speed: 200,
      level: 1,
      hMove: false,
      image: 'enemyBlack4.png',
    ),
    EnemyData(
      killPoint: 6,
      speed: 250,
      level: 2,
      hMove: false,
      image: 'enemyBlack5.png',
    ),
    EnemyData(
      killPoint: 6,
      speed: 250,
      level: 2,
      hMove: false,
      image: 'enemyBlue1.png',
    ),
    EnemyData(
      killPoint: 6,
      speed: 250,
      level: 2,
      hMove: false,
      image: 'enemyBlue2.png',
    ),
    EnemyData(
      killPoint: 6,
      speed: 250,
      level: 2,
      hMove: true,
      image: 'enemyBlue3.png',
    ),
    EnemyData(
      killPoint: 10,
      speed: 350,
      level: 3,
      hMove: false,
      image: 'enemyBlue4.png',
    ),
    EnemyData(
      killPoint: 10,
      speed: 350,
      level: 3,
      hMove: false,
      image: 'enemyBlue5.png',
    ),
    EnemyData(
      killPoint: 10,
      speed: 400,
      level: 3,
      hMove: true,
      image: 'enemyGreen1.png',
    ),
    EnemyData(
      killPoint: 10,
      speed: 400,
      level: 3,
      hMove: false,
      image: 'enemyGreen2.png',
    ),
    EnemyData(
      killPoint: 10,
      speed: 400,
      level: 4,
      hMove: false,
      image: 'enemyGreen3.png',
    ),
    EnemyData(
      killPoint: 50,
      speed: 250,
      level: 4,
      hMove: true,
      image: 'enemyGreen4.png',
    ),
    EnemyData(
      killPoint: 50,
      speed: 250,
      level: 4,
      hMove: false,
      image: 'enemyGreen5.png',
    ),
    EnemyData(
      killPoint: 50,
      speed: 250,
      level: 4,
      hMove: false,
      image: 'enemyRed1.png',
    )
  ];
}
