// This component class is responsible for spawning new meteor
// components.
import 'dart:math';

import 'package:flame/components.dart';
import 'game.dart';
import 'knows_game_size.dart';
import 'meteor.dart';

class MeteorManager extends Component
    with KnowsGameSize, HasGameRef<MoretiniInvaders> {
  // The timer which runs the enemy spawner code at regular interval of time.
  late Timer _timer;

  // Controls for how long EnemyManager should stop spawning new enemies.
  late Timer _freezeTimer;

  // Holds an object of Random class to generate random numbers.
  Random random = Random();

  MeteorManager() : super() {
    // Sets the timer to call _spawnEnemy() after every 1 second, until timer is explicitly stops.
    _timer = Timer(0.2, onTick: _spawnMeteor, repeat: true);

    // Sets freeze time to 2 seconds. After 2 seconds spawn timer will start again.
    _freezeTimer = Timer(2, onTick: () {
      _timer.start();
    });
  }

  // Spawn meteor at random position on top
  void _spawnMeteor() {
    final size = Vector2(20, 20) + Vector2(1, 1) * 50 * random.nextDouble();
    final speed = 150 + 400 * random.nextDouble();

    // Random num from -1 to 2
    final rnd = 3 * random.nextDouble() - 1;
    final position = Vector2(gameRef.size.x * rnd, -size[1]);

    Meteor meteor = Meteor(
        sprite: gameRef.meteorSprites[random.nextInt(4)],
        position: position,
        size: size,
        speed: speed);

    // Set anchor to centre
    meteor.anchor = Anchor.center;

    // Add to the component list of game instance
    gameRef.add(meteor);
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
}
